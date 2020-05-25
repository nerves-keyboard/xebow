defmodule Xebow.RGBMatrix do
  use GenServer

  alias Circuits.SPI
  alias Xebow.Animation

  import Xebow.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:spidev, :animation]
  end

  @type any_color_model ::
          Chameleon.Color.RGB.t()
          | Chameleon.Color.CMYK.t()
          | Chameleon.Color.Hex.t()
          | Chameleon.Color.HSL.t()
          | Chameleon.Color.HSV.t()
          | Chameleon.Color.Keyword.t()
          | Chameleon.Color.Pantone.t()

  @type pixel :: {non_neg_integer, non_neg_integer}
  @type pixel_color :: any_color_model

  @spi_device "spidev0.0"
  @spi_speed_hz 4_000_000
  @sof <<0, 0, 0, 0>>
  @eof <<255, 255, 255, 255>>

  # Client

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def next_animation do
    GenServer.cast(__MODULE__, :next_animation)
  end

  def previous_animation do
    GenServer.cast(__MODULE__, :previous_animation)
  end

  @spec play_animation(animation :: Animation.t()) :: :ok
  def play_animation(animation) do
    GenServer.cast(__MODULE__, {:play_animation, animation})
  end

  # Server

  @impl GenServer
  def init([]) do
    {:ok, spidev} =
      SPI.open(@spi_device,
        speed_hz: @spi_speed_hz
      )

    send(self(), :get_next_frame)

    [initial_animation_type | _] = Animation.types()
    animation = Animation.new(type: initial_animation_type)

    state =
      %State{spidev: spidev}
      |> set_animation(animation)

    {:ok, state}
  end

  defp set_animation(state, animation) do
    %State{state | animation: animation}
  end

  @impl GenServer
  def handle_info(:get_next_frame, state) do
    animation = Animation.next_frame(state.animation)
    paint(state.spidev, animation.next_frame)

    Process.send_after(self(), :get_next_frame, animation.delay_ms)
    {:noreply, set_animation(state, animation)}
  end

  @impl GenServer
  def handle_info({:reset_animation, reset_animation}, state) do
    {:noreply, set_animation(state, reset_animation)}
  end

  defp paint(spidev, frame) do
    colors =
      frame.pixel_map
      |> Enum.sort()
      |> Enum.map(fn {_cord, color} -> color end)

    data =
      Enum.reduce(colors, @sof, fn color, acc ->
        rgb = Chameleon.convert(color, Chameleon.Color.RGB)
        acc <> <<227, rgb.b, rgb.g, rgb.r>>
      end) <> @eof

    SPI.transfer(spidev, data)
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

  def handle_cast({:play_animation, %{loop: 0} = _animation}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:play_animation, animation}, state) do
    {:noreply, set_animation(state, animation)}
  end
end
