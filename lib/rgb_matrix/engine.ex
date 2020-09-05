defmodule RGBMatrix.Engine do
  @moduledoc """
  Renders [`Animation`](`RGBMatrix.Animation`)s and outputs colors to be
  displayed by anything that registers itself with `register_paintable/2`.
  """

  use GenServer

  alias Layout.LED
  alias RGBMatrix.Animation

  @type frame :: %{LED.id() => RGBMatrix.any_color_model()}

  defmodule State do
    @moduledoc false
    defstruct [:leds, :animation, :paintables, :last_frame, :timer]
  end

  # Client

  @doc """
  Start the engine.

  This module registers its process globally and is expected to be started by a
  supervisor.
  """
  @spec start_link(any) :: GenServer.on_start()
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Sets the given animation as the currently active animation.
  """
  @spec set_animation(animation :: Animation.t()) :: :ok
  def set_animation(animation) do
    GenServer.cast(__MODULE__, {:set_animation, animation})
  end

  @doc """
  Register a paint function for the engine to send frames to.

  This function is idempotent.
  """
  @spec register_paintable(paint_fn :: function) :: {:ok, function, frame}
  def register_paintable(paint_fn) do
    {:ok, frame} = GenServer.call(__MODULE__, {:register_paintable, paint_fn})
    {:ok, paint_fn, frame}
  end

  @doc """
  Unregister a paint function so the engine no longer sends frames to it.

  This function is idempotent.
  """
  @spec unregister_paintable(paint_fn :: function) :: :ok
  def unregister_paintable(paint_fn) do
    GenServer.call(__MODULE__, {:unregister_paintable, paint_fn})
  end

  @doc """
  Sends interaction events to the engine. Animations may or may not respond
  to these interaction events.
  """
  @spec interact(led :: LED.t()) :: :ok
  def interact(led) do
    GenServer.cast(__MODULE__, {:interact, led})
  end

  # Server

  @impl GenServer
  def init(_args) do
    state = %State{
      leds: leds,
      last_frame: frame,
      paintables: MapSet.new()
    }

    {:ok, state}
  end

  defp add_paintable(paint_fn, state) do
    paintables = MapSet.put(state.paintables, paint_fn)
    %State{state | paintables: paintables}
  end

  defp remove_paintable(paint_fn, state) do
    paintables = MapSet.delete(state.paintables, paint_fn)
    %State{state | paintables: paintables}
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
    {render_in, new_colors, animation} = Animation.render(state.animation)

    frame = update_frame(state.last_frame, new_colors)

    state =
      %State{state | animation: animation, last_frame: frame}
      |> paint(frame)
      |> schedule_next_render(render_in)

    {:noreply, state}
  end

  defp update_frame(frame, new_colors) do
    Enum.reduce(new_colors, frame, fn {led_id, color}, frame ->
      Map.put(frame, led_id, color)
    end)
  end

  defp paint(state, frame) do
    Enum.reduce(state.paintables, state, fn paint_fn, state ->
      case paint_fn.(frame) do
        :ok -> state
        :unregister -> remove_paintable(paint_fn, state)
      end
    end)
  end

  @impl GenServer
  def handle_cast({:set_animation, animation}, state) do
    state =
      %State{state | animation: animation, last_frame: %{}}
      |> schedule_next_render(0)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:interact, led}, state) do
    {render_in, animation} = Animation.interact(state.animation, led)

    state =
      %State{state | animation: animation}
      |> schedule_next_render(render_in)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:register_paintable, paint_fn}, _from, state) do
    state = add_paintable(paint_fn, state)
    {:reply, {:ok, state.last_frame}, state}
  end

  @impl GenServer
  def handle_call({:unregister_paintable, key}, _from, state) do
    state = remove_paintable(key, state)
    {:reply, :ok, state}
  end
end
