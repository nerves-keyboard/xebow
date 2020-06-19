defmodule Xebow.Engine do
  @moduledoc """
  Renders [`Animation`](`Xebow.Animation`)s and outputs
  [`Frame`](`Xebow.Frame`)s to be displayed.
  """

  use GenServer

  import Xebow.Utils, only: [mod: 2]

  alias Xebow.Animation

  defmodule State do
    @moduledoc false
    defstruct [:animation, :paint_fn]
  end

  # Client

  @doc """
  Start the engine.

  This function accepts a tuple that contains the following arguments:
  - `paintable_module` - A module that implements `get_paint_fn`, which
    returns an anonymous function that accepts a frame to paint.
  """
  @spec start_link({paintable_module :: module}) :: GenServer.on_start()
  def start_link({paintable_module}) do
    paint_fn = paintable_module.get_paint_fn
    GenServer.start_link(__MODULE__, {paint_fn}, name: __MODULE__)
  end

  @doc """
  Cycle to the next animation and play it.
  """
  @spec next_animation :: :ok
  def next_animation do
    GenServer.cast(__MODULE__, :next_animation)
  end

  @doc """
  Cycle to the previous animation and play it.
  """
  @spec previous_animation :: :ok
  def previous_animation do
    GenServer.cast(__MODULE__, :previous_animation)
  end

  @doc """
  Play the given animation.

  Note that the animation can be played synchronously by passing `:false` for the `:async` option. However, only
  looping (animations with `:loop` >= 1) animations may be played this way. This is to ensure that the caller is not
  blocked forever.
  """
  @spec play_animation(animation :: Animation.t(), opts :: keyword()) :: :ok
  def play_animation(animation, opts \\ []) do
    async? = Keyword.get(opts, :async, true)

    if async? do
      GenServer.cast(__MODULE__, {:play_animation, animation})
    else
      GenServer.call(__MODULE__, {:play_animation, animation})
    end
  end

  # Server

  @impl GenServer
  def init({paint_fn}) do
    send(self(), :get_next_frame)

    [initial_animation_type | _] = Animation.types()
    animation = Animation.new(type: initial_animation_type)

    state =
      %State{paint_fn: paint_fn}
      |> set_animation(animation)

    {:ok, state}
  end

  defp set_animation(state, animation) do
    %State{state | animation: animation}
  end

  @impl GenServer
  def handle_info(:get_next_frame, state) do
    animation = Animation.next_frame(state.animation)
    state.paint_fn.(animation.next_frame)

    Process.send_after(self(), :get_next_frame, animation.delay_ms)
    {:noreply, set_animation(state, animation)}
  end

  @impl GenServer
  def handle_info({:reset_animation, reset_animation}, state) do
    {:noreply, set_animation(state, reset_animation)}
  end

  @impl GenServer
  def handle_info({:reply, from, reset_animation}, state) do
    GenServer.reply(from, :ok)

    {:noreply, set_animation(state, reset_animation)}
  end

  @impl GenServer
  def handle_cast(:next_animation, state) do
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    next = mod(current + 1, num)
    animation_type = Enum.at(animation_types, next)
    animation = Animation.new(type: animation_type)

    {:noreply, set_animation(state, animation)}
  end

  @impl GenServer
  def handle_cast(:previous_animation, state) do
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    previous = mod(current - 1, num)
    animation_type = Enum.at(animation_types, previous)
    animation = Animation.new(type: animation_type)

    {:noreply, set_animation(state, animation)}
  end

  @impl GenServer
  def handle_cast({:play_animation, %{loop: loop} = animation}, state) when loop >= 1 do
    current_animation = state.animation
    expected_duration = Animation.duration(animation)
    Process.send_after(self(), {:reset_animation, current_animation}, expected_duration)

    {:noreply, set_animation(state, animation)}
  end

  @impl GenServer
  def handle_cast({:play_animation, %{loop: 0} = _animation}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:play_animation, animation}, state) do
    {:noreply, set_animation(state, animation)}
  end

  @impl GenServer
  def handle_call({:play_animation, %{loop: loop} = animation}, from, state) when loop >= 1 do
    current_animation = state.animation
    duration = Animation.duration(animation)
    Process.send_after(self(), {:reply, from, current_animation}, duration)

    {:noreply, set_animation(state, animation)}
  end
end
