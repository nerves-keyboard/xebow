require Logger

defmodule RGBMatrix.Engine do
  @moduledoc """
  Renders [`Effect`](`RGBMatrix.Effect`)s and outputs colors to be displayed by
  [`Paintable`](`RGBMatrix.Paintable`)s.
  """

  use GenServer

  alias Layout.LED
  alias RGBMatrix.Effect

  defmodule State do
    @moduledoc false
    defstruct [:leds, :effect, :paintables, :last_frame, :timer]
  end

  # Client

  @doc """
  Start the engine.

  This module registers its process globally and is expected to be started by
  a supervisor.

  This function accepts the following arguments as a tuple:
  - `leds` - The list of LEDs to be painted on.
  - `initial_effect` - The Effect type to initialize and play when the engine
      starts.
  - `paintables` - A list of modules to output colors to that implement the
      `RGBMatrix.Paintable` behavior. If you want to register your paintables
      dynamically, set this to an empty list `[]`.
  """
  @spec start_link(
          {leds :: [LED.t()], initial_effect_type :: Effect.type(), paintables :: list(module)}
        ) ::
          GenServer.on_start()
  def start_link({leds, initial_effect_type, paintables}) do
    GenServer.start_link(__MODULE__, {leds, initial_effect_type, paintables}, name: __MODULE__)
  end

  @doc """
  Sets the given effect as the currently active effect.
  """
  @spec set_effect(effect_type :: Effect.type(), opts :: keyword()) :: :ok
  def set_effect(effect_type) do
    GenServer.cast(__MODULE__, {:set_effect, effect_type})
  end

  @doc """
  Register a `RGBMatrix.Paintable` for the engine to paint pixels to.
  This function is idempotent.
  """
  @spec register_paintable(paintable :: module) :: :ok
  def register_paintable(paintable) do
    GenServer.call(__MODULE__, {:register_paintable, paintable})
  end

  @doc """
  Unregister a `RGBMatrix.Paintable` so the engine no longer paints pixels to it.
  This function is idempotent.
  """
  @spec unregister_paintable(paintable :: module) :: :ok
  def unregister_paintable(paintable) do
    GenServer.call(__MODULE__, {:unregister_paintable, paintable})
  end

  @spec interact(led :: LED.t()) :: :ok
  def interact(led) do
    GenServer.cast(__MODULE__, {:interact, led})
  end

  # Server

  @impl GenServer
  def init({leds, initial_effect_type, paintables}) do
    black = Chameleon.HSV.new(0, 0, 0)
    frame = Map.new(leds, &{&1.id, black})

    initial_state = %State{leds: leds, last_frame: frame, paintables: %{}}

    state =
      Enum.reduce(paintables, initial_state, fn paintable, state ->
        add_paintable(paintable, state)
      end)
      |> set_effect(initial_effect_type)

    {:ok, state}
  end

  defp add_paintable(paintable, state) do
    paintables = Map.put(state.paintables, paintable, paintable.get_paint_fn)
    %State{state | paintables: paintables}
  end

  defp remove_paintable(paintable, state) do
    paintables = Map.delete(state.paintables, paintable)
    %State{state | paintables: paintables}
  end

  defp set_effect(state, effect_type) do
    {render_in, effect} = Effect.new(effect_type, state.leds)

    state = schedule_next_render(state, render_in)

    %State{state | effect: effect}
  end

  defp schedule_next_render(state, :ignore) do
    state
  end

  defp schedule_next_render(state, :never) do
    cancel_timer(state)
  end

  defp schedule_next_render(state, 0) do
    send(self(), :render)
    cancel_timer(state)
  end

  defp schedule_next_render(state, ms) when is_integer(ms) and ms > 0 do
    state = cancel_timer(state)
    %{state | timer: Process.send_after(self(), :render, ms)}
  end

  defp cancel_timer(%{timer: nil} = state), do: state

  defp cancel_timer(state) do
    Process.cancel_timer(state.timer)
    %{state | timer: nil}
  end

  @impl true
  def handle_info(:render, state) do
    {new_colors, render_in, effect} = Effect.render(state.effect)

    frame = update_frame(state.last_frame, new_colors)

    state.paintables
    |> Map.values()
    |> Enum.each(fn paint_fn ->
      paint_fn.(frame)
    end)

    state = schedule_next_render(state, render_in)
    state = %State{state | effect: effect, last_frame: frame}

    {:noreply, state}
  end

  defp update_frame(frame, new_colors) do
    Enum.reduce(new_colors, frame, fn {led_id, color}, frame ->
      Map.put(frame, led_id, color)
    end)
  end

  @impl GenServer
  def handle_cast({:set_effect, effect_type}, state) do
    state = set_effect(state, effect_type)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:interact, led}, state) do
    {render_in, effect} = Effect.interact(state.effect, led)
    state = schedule_next_render(state, render_in)
    state = %State{state | effect: effect}

    {:noreply, %State{state | effect: effect}}
  end

  @impl GenServer
  def handle_call({:register_paintable, paintable}, _from, state) do
    state = add_paintable(paintable, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:unregister_paintable, paintable}, _from, state) do
    state = remove_paintable(paintable, state)
    {:reply, :ok, state}
  end
end
