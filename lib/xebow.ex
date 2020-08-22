defmodule Xebow do
  @moduledoc """
  Xebow is an Elixir-based firmware for keyboards. Currently, it is working on the Raspberry Pi0
  Keybow kit.
  """

  alias RGBMatrix.{Animation, Engine}
  alias Xebow.{Excalibur, Keybow, Settings}

  require Logger

  @layout_host Layout.new([])

  @spec layout(atom) :: Layout.t()
  def layout(:host), do: @layout_host
  def layout(:keybow), do: Keybow.Layout.layout()
  def layout(:excalibur), do: Excalibur.Layout.layout()

  @type animations :: [Animation.t()]
  @type animation_params :: %{String.t() => atom | number | String.t()}

  defmodule State do
    @moduledoc false
    defstruct [:current_index, :active_animations, :count_of_active_animations]
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
        count_of_active_animations: 0
      }
      |> update_state_with_animation_types(active_animation_types)

    case current_animation(state) do
      nil -> nil
      animation -> Engine.set_animation(animation)
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
  def handle_cast({:set_active_animation_types, active_animation_types}, state) do
    state = update_state_with_animation_types(state, active_animation_types)

    Settings.save_active_animations!(active_animation_types)

    case current_animation(state) do
      nil -> nil
      animation -> Engine.set_animation(animation)
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

    state = %State{state | current_index: new_index}
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

    state = %State{state | current_index: new_index}
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

    Engine.set_animation(current_animation(state))
    {:noreply, state}
  end

  defp current_animation(state) do
    state.active_animations[state.current_index]
  end

  defp initialize_animation(animation_type) do
    target = Xebow.Application.target()
    layout = layout(target)
    leds = Layout.leds(layout)
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
end
