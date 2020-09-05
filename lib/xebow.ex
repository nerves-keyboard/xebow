defmodule Xebow do
  @moduledoc """
  Xebow is an Elixir-based firmware for keyboards. Currently, it is working on the Raspberry Pi0
  Keybow kit.
  """

  alias RGBMatrix.{Animation, Engine}
  alias Xebow.Settings

  require Logger

  @layout Layout.load_from_config()

  @spec layout() :: Layout.t()
  def layout, do: @layout

  @type animations :: [Animation.t()]
  @type animation_params :: %{String.t() => atom | number | String.t()}

  defmodule State do
    @moduledoc false
    defstruct [:current_index, :active_animations, :count_of_active_animations, :configurables]
  end

  use GenServer

  # Client Implementations:

  @doc """
  Starts the Xebow application, which manages initialization of animations, as well
  as switching between active animations. It also maintains animation config state
  and persists it in memory between animation changes.
  """
  @spec start_link(any) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Returns a list of active animation types, which can be played by the user.
  """
  @spec get_active_animation_types() :: [Animation.type()]
  def get_active_animation_types do
    GenServer.call(__MODULE__, :get_active_animation_types)
  end

  @doc """
  Set the active animation types, which can be played by the user.
  """
  @spec set_active_animation_types(active_animation_types :: [Animation.type()]) :: :ok
  def set_active_animation_types(active_animation_types) do
    GenServer.cast(__MODULE__, {:set_active_animation_types, active_animation_types})
  end

  @doc """
  Gets the animation configuration. This retrievs current values, which allows for
  changes to be made with `update_animation_config/1`
  """
  @spec get_animation_config() ::
          {Animation.Config.t(), keyword(Animation.Config.t())}
          | nil
  def get_animation_config do
    GenServer.call(__MODULE__, :get_animation_config)
  end

  @doc """
  Switches to the next active animation
  """
  @spec next_animation() :: :ok
  def next_animation do
    GenServer.cast(__MODULE__, :next_animation)
  end

  @doc """
  Switches to the previous active animation
  """
  @spec previous_animation() :: :ok
  def previous_animation do
    GenServer.cast(__MODULE__, :previous_animation)
  end

  @doc """
  Updates the configuration for the current animation
  """
  @spec update_animation_config(animation_params) :: :ok
  def update_animation_config(params) do
    GenServer.cast(__MODULE__, {:update_animation_config, params})
  end

  @doc """
  Register a config function for the engine to send animation configuration to
  when it changes.

  This function is idempotent.
  """
  @spec register_configurable(config_fn :: function) :: {:ok, function}
  def register_configurable(config_fn) do
    :ok = GenServer.call(__MODULE__, {:register_configurable, config_fn})
    {:ok, config_fn}
  end

  @doc """
  Unregister a config function so the engine no longer sends animation
  configuration to it.

  This function is idempotent.
  """
  @spec unregister_configurable(config_fn :: function) :: :ok
  def unregister_configurable(config_fn) do
    GenServer.call(__MODULE__, {:unregister_configurable, config_fn})
  end

  # Server Implementations:

  @impl GenServer
  def init(_) do
    active_animation_types =
      case Settings.load_active_animations() do
        {:ok, active_animation_types} ->
          active_animation_types

        {:error, reason} ->
          Logger.warn("Failed to load active animations: #{inspect(reason)}")
          Animation.types()
      end

    state =
      %State{
        current_index: 0,
        active_animations: %{},
        count_of_active_animations: 0,
        configurables: MapSet.new()
      }
      |> update_state_with_animation_types(active_animation_types)

    case current_animation(state) do
      nil ->
        nil

      animation ->
        inform_configurables(state)
        Engine.set_animation(animation)
        state
    end

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_active_animation_types, _from, state) do
    active_animation_types =
      state.active_animations
      |> Map.values()
      |> Enum.map(& &1.type)

    {:reply, active_animation_types, state}
  end

  @impl GenServer
  def handle_call(:get_animation_config, _from, state) do
    config =
      case current_animation(state) do
        nil -> nil
        animation -> Animation.get_config(animation)
      end

    {:reply, config, state}
  end

  @impl GenServer
  def handle_call({:register_configurable, config_fn}, _from, state) do
    state = add_configurable(config_fn, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:unregister_configurable, config_fn}, _from, state) do
    state = remove_configurable(config_fn, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_cast({:set_active_animation_types, active_animation_types}, state) do
    state = update_state_with_animation_types(state, active_animation_types)

    Settings.save_active_animations!(active_animation_types)

    case current_animation(state) do
      nil ->
        nil

      animation ->
        inform_configurables(state)
        Engine.set_animation(animation)
        state
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:next_animation, %State{count_of_active_animations: 0} = state) do
    {:noreply, state}
  end

  def handle_cast(:next_animation, state) do
    count_of_active_animations = state.count_of_active_animations

    new_index =
      case state.current_index + 1 do
        i when i >= count_of_active_animations -> 0
        i -> i
      end

    state = %State{state | current_index: new_index} |> inform_configurables()
    Engine.set_animation(current_animation(state))
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:previous_animation, %State{count_of_active_animations: 0} = state) do
    {:noreply, state}
  end

  def handle_cast(:previous_animation, state) do
    new_index =
      case state.current_index - 1 do
        i when i < 0 -> state.count_of_active_animations - 1
        i -> i
      end

    state = %State{state | current_index: new_index} |> inform_configurables()
    Engine.set_animation(current_animation(state))
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:update_animation_config, params}, state) do
    updated_animation = Animation.update_config(current_animation(state), params)

    state =
      put_in(
        state.active_animations[state.current_index],
        updated_animation
      )
      |> inform_configurables()

    Engine.set_animation(current_animation(state))
    {:noreply, state}
  end

  defp current_animation(state) do
    state.active_animations[state.current_index]
  end

  defp initialize_animation(animation_type) do
    leds = Layout.leds(@layout)
    Animation.new(animation_type, leds)
  end

  defp update_state_with_animation_types(state, animation_types) do
    count_of_active_animations = length(animation_types)

    active_animations =
      animation_types
      |> Stream.map(&new_or_existing_animation(&1, state.active_animations))
      |> Stream.with_index()
      |> Stream.map(fn {animation, index} -> {index, animation} end)
      |> Enum.into(%{})

    %State{
      state
      | current_index: 0,
        active_animations: active_animations,
        count_of_active_animations: count_of_active_animations
    }
  end

  defp new_or_existing_animation(animation_type, active_animations) do
    existing_animation =
      active_animations
      |> Map.values()
      |> Enum.find(fn animation ->
        animation.type == animation_type
      end)

    existing_animation || initialize_animation(animation_type)
  end

  defp add_configurable(config_fn, state) do
    configurables = MapSet.put(state.configurables, config_fn)
    %State{state | configurables: configurables}
  end

  defp remove_configurable(config_fn, state) do
    configurables = MapSet.delete(state.configurables, config_fn)
    %State{state | configurables: configurables}
  end

  defp inform_configurables(state) do
    config = Animation.get_config(current_animation(state))

    Enum.reduce(state.configurables, state, fn config_fn, state ->
      case config_fn.(config) do
        :ok -> state
        :unregister -> remove_configurable(config_fn, state)
      end
    end)
  end
end
