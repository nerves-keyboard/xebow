defmodule Xebow do
  @moduledoc """
  Xebow is an Elixir-based firmware for keyboards. Currently, it is working on the Raspberry Pi0
  Keybow kit.
  """

  alias Layout.{Key, LED}
  alias RGBMatrix.{Animation, Engine}

  @leds [
    LED.new(:l001, 0, 0),
    LED.new(:l002, 1, 0),
    LED.new(:l003, 2, 0),
    LED.new(:l004, 0, 1),
    LED.new(:l005, 1, 1),
    LED.new(:l006, 2, 1),
    LED.new(:l007, 0, 2),
    LED.new(:l008, 1, 2),
    LED.new(:l009, 2, 2),
    LED.new(:l010, 0, 3),
    LED.new(:l011, 1, 3),
    LED.new(:l012, 2, 3)
  ]

  @keys [
    Key.new(:k001, 0, 0, led: :l001),
    Key.new(:k002, 1, 0, led: :l002),
    Key.new(:k003, 2, 0, led: :l003),
    Key.new(:k004, 0, 1, led: :l004),
    Key.new(:k005, 1, 1, led: :l005),
    Key.new(:k006, 2, 1, led: :l006),
    Key.new(:k007, 0, 2, led: :l007),
    Key.new(:k008, 1, 2, led: :l008),
    Key.new(:k009, 2, 2, led: :l009),
    Key.new(:k010, 0, 3, led: :l010),
    Key.new(:k011, 1, 3, led: :l011),
    Key.new(:k012, 2, 3, led: :l012)
  ]

  @layout Layout.new(@keys, @leds)

  @spec layout() :: Layout.t()
  def layout, do: @layout

  @type animations :: [Animation.t()]
  @type animation_params :: %{String.t() => atom | number | String.t()}

  defmodule State do
    @moduledoc false
    defstruct [:current_animation, :next_list, :previous_list]
  end

  use GenServer

  # Client Implementations:

  @doc """
  Starts the Xebow application, which manages initialization of animations, as well
  as switching between active animations. It also maintains animation config state
  and persists it in memory between animation changes.
  """
  @spec start_link([]) :: GenServer.on_start()
  def start_link([]) do
    GenServer.start_link(__MODULE__, Animation.types(), name: __MODULE__)
  end

  @doc """
  Gets the animation configuration. This retrievs current values, which allows for
  changes to be made with `update_animation_config/1`
  """
  @spec get_animation_config() :: {Animation.Config.t(), keyword(Animation.Config.t())}
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
  @spec update_animation_config(animation_params) ::
          :ok
  def update_animation_config(params) do
    GenServer.cast(__MODULE__, {:update_animation_config, params})
  end

  # Server Implementations:

  @impl GenServer
  def init(types) do
    active_animations =
      types
      |> Enum.map(&initialize_animation/1)

    current = hd(active_animations)
    Engine.set_animation(current)

    state = %State{
      current_animation: current,
      next_list: active_animations,
      previous_list: []
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_animation_config, _from, state) do
    {:reply, Animation.get_config(state.current_animation), state}
  end

  @impl GenServer
  def handle_cast(:next_animation, state) do
    case state.next_list do
      [] ->
        [new_current | next_list] = Enum.reverse([state.current_animation | state.previous_list])
        Engine.set_animation(new_current)

        state = %{
          state
          | current_animation: new_current,
            next_list: next_list,
            previous_list: []
        }

        {:noreply, state}

      [new_current | next_list] ->
        Engine.set_animation(new_current)

        state = %{
          state
          | current_animation: new_current,
            next_list: next_list,
            previous_list: [state.current_animation | state.previous_list]
        }

        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast(:previous_animation, state) do
    case state.previous_list do
      [] ->
        [new_current | previous_list] = Enum.reverse([state.current_animation | state.next_list])
        Engine.set_animation(new_current)

        state = %{
          state
          | current_animation: new_current,
            next_list: [],
            previous_list: previous_list
        }

        {:noreply, state}

      [new_current | previous_list] ->
        Engine.set_animation(new_current)

        state = %{
          state
          | current_animation: new_current,
            next_list: [state.current_animation | state.next_list],
            previous_list: previous_list
        }

        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast({:update_animation_config, params}, state) do
    updated_animation = Animation.update_config(state.current_animation, params)
    Engine.set_animation(updated_animation)

    state = %{state | current_animation: updated_animation}

    {:noreply, state}
  end

  defp initialize_animation(animation_type) do
    Animation.new(animation_type, @leds)
  end
end
