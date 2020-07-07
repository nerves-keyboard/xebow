require Logger

defmodule RGBMatrix.Engine do
  @moduledoc """
  Renders [`Animation`](`RGBMatrix.Animation`)s and outputs colors to be
  displayed by anything that registers itself with `register_paintable/2`.
  """

  use GenServer

  alias Layout.LED
  alias RGBMatrix.Animation

  defmodule State do
    @moduledoc false
    defstruct [:leds, :animation, :paintables, :last_frame, :timer, :configurables]
  end

  # Client

  @doc """
  Start the engine.

  This module registers its process globally and is expected to be started by a
  supervisor.

  This function accepts the following arguments as a tuple:
  - `leds` - The list of LEDs to be painted on.
  - `initial_animation` - The Animation type to initialize and play when the
    engine starts.
  """
  @spec start_link({leds :: [LED.t()], initial_animation_type :: Animation.type()}) ::
          GenServer.on_start()
  def start_link({leds, initial_animation_type}) do
    GenServer.start_link(__MODULE__, {leds, initial_animation_type}, name: __MODULE__)
  end

  @doc """
  Sets the given animation as the currently active animation.
  """
  @spec set_animation(animation_type :: Animation.type(), opts :: keyword()) :: :ok
  def set_animation(animation_type) do
    GenServer.cast(__MODULE__, {:set_animation, animation_type})
  end

  @doc """
  Register a paint function for the engine to send frames to. This function is
  idempotent.
  """
  @spec register_paintable(key :: any, paint_fn :: function) :: :ok
  def register_paintable(key, paint_fn) do
    GenServer.call(__MODULE__, {:register_paintable, {key, paint_fn}})
  end

  @doc """
  Unregister a paint function so the engine no longer sends frames to it. This
  function is idempotent.
  """
  @spec unregister_paintable(key :: any) :: :ok
  def unregister_paintable(key) do
    GenServer.call(__MODULE__, {:unregister_paintable, key})
  end

  @doc """
  Sends an interaction events to the engine. Animations may or may not respond
  to these interaction events.
  """
  @spec interact(led :: LED.t()) :: :ok
  def interact(led) do
    GenServer.cast(__MODULE__, {:interact, led})
  end

  @doc """
  Retrieves the current animation's configuration and configuration schema.
  """
  @spec get_animation_config() :: {config :: any, config_schema :: any}
  def get_animation_config do
    GenServer.call(__MODULE__, :get_animation_config)
  end

  @doc """
  Updates the current animation's configuration.
  """
  @spec update_animation_config(params :: map) :: :ok | :error
  def update_animation_config(params) do
    GenServer.call(__MODULE__, {:update_animation_config, params})
  end

  def register_configurable(key, config_fn) do
    GenServer.call(__MODULE__, {:register_configurable, {key, config_fn}})
  end

  def unregister_configurable(key) do
    GenServer.call(__MODULE__, {:unregister_configurable, key})
  end

  # Server

  @impl GenServer
  def init({leds, initial_animation_type}) do
    black = Chameleon.HSV.new(0, 0, 0)
    frame = Map.new(leds, &{&1.id, black})

    state =
      %State{leds: leds, last_frame: frame, paintables: %{}, configurables: %{}}
      |> set_animation(initial_animation_type)

    {:ok, state}
  end

  defp add_paintable({key, paint_fn}, state) do
    paintables = Map.put(state.paintables, key, paint_fn)
    %State{state | paintables: paintables}
  end

  defp remove_paintable(key, state) do
    paintables = Map.delete(state.paintables, key)
    %State{state | paintables: paintables}
  end

  defp set_animation(state, animation_type) do
    {render_in, animation} = Animation.new(animation_type, state.leds)

    state = %State{state | animation: animation}
    state = schedule_next_render(state, render_in)
    state = inform_all_configurables(state)

    state
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
    {new_colors, render_in, animation} = Animation.render(state.animation)

    frame = update_frame(state.last_frame, new_colors)

    state = paint_all_paintables(state, frame)
    state = schedule_next_render(state, render_in)
    state = %State{state | animation: animation, last_frame: frame}

    {:noreply, state}
  end

  defp update_frame(frame, new_colors) do
    Enum.reduce(new_colors, frame, fn {led_id, color}, frame ->
      Map.put(frame, led_id, color)
    end)
  end

  defp paint_all_paintables(state, frame) do
    Enum.reduce(state.paintables, state, fn {key, paint_fn}, state ->
      case paint_fn.(frame) do
        :ok -> state
        :unregister -> remove_paintable(key, state)
      end
    end)
  end

  @impl GenServer
  def handle_cast({:set_animation, animation_type}, state) do
    state = set_animation(state, animation_type)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:interact, led}, state) do
    {render_in, animation} = Animation.interact(state.animation, led)
    state = schedule_next_render(state, render_in)
    state = %State{state | animation: animation}

    {:noreply, %State{state | animation: animation}}
  end

  @impl GenServer
  def handle_call({:register_paintable, paintable}, _from, state) do
    state = add_paintable(paintable, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:unregister_paintable, key}, _from, state) do
    state = remove_paintable(key, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:get_animation_config, _from, state) do
    {:reply, Animation.get_config(state.animation), state}
  end

  @impl GenServer
  def handle_call({:update_animation_config, params}, _from, state) do
    animation = Animation.update_config(state.animation, params)

    state = %State{state | animation: animation}
    state = inform_all_configurables(state)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:register_configurable, configurable}, _from, state) do
    state = add_configurable(configurable, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:unregister_configurable, key}, _from, state) do
    state = remove_configurable(key, state)
    {:reply, :ok, state}
  end

  defp add_configurable({key, paint_fn}, state) do
    configurables = Map.put(state.configurables, key, paint_fn)
    %State{state | configurables: configurables}
  end

  defp remove_configurable(key, state) do
    configurables = Map.delete(state.configurables, key)
    %State{state | configurables: configurables}
  end

  defp inform_all_configurables(state) do
    config = Animation.get_config(state.animation)

    Enum.reduce(state.configurables, state, fn {key, config_fn}, state ->
      case config_fn.(config) do
        :ok -> state
        :unregister -> remove_paintable(key, state)
      end
    end)
  end
end
