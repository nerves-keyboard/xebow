defmodule Xebow.RGBMatrix do
  use GenServer

  alias Circuits.SPI
  alias Xebow.{Animation, AnimationFrame}

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

  def flash(color, sleep_ms \\ 250) do
    GenServer.cast(__MODULE__, {:flash, color, sleep_ms})
  end

  def next_animation do
    GenServer.cast(__MODULE__, :next_animation)
  end

  def previous_animation do
    GenServer.cast(__MODULE__, :previous_animation)
  end

  @spec play_one_shot(animation :: Animation.t()) :: :ok
  def play_one_shot(animation) do
    expected_duration = length(animation.frames) * animation.delay_ms

    GenServer.call(
      __MODULE__,
      {:play_one_shot, animation, expected_duration},
      expected_duration + 50
    )
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

    send(self(), :get_next_state)

    [initial_animation_type | _] = Animation.types()

    state =
      %State{spidev: spidev}
      |> set_animation(initial_animation_type)

    {:ok, state}
  end

  defp set_animation(state, animation_type) do
    %State{state | animation: Animation.init_state(animation_type, Xebow.Utils.pixels())}
  end

  @impl GenServer
  def handle_info(:get_next_state, state) do
    new_animation_state = Animation.next_state(state.animation)

    paint(state.spidev, new_animation_state.next_frame)

    Process.send_after(self(), :get_next_state, new_animation_state.delay_ms)

    {:noreply, %State{state | animation: new_animation_state}}
  end

  @impl GenServer
  def handle_info({:reply_one_shot, from, reset_animation}, state) do
    GenServer.reply(from, :ok)
    {:noreply, %State{state | animation: reset_animation}}
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

  defp paint_solid(spidev, color) do
    color = Chameleon.Keyword.new(color)
    pixels = Xebow.Utils.pixels()
    animation_frame = AnimationFrame.solid_color(pixels, color)
    paint(spidev, animation_frame)
  end

  @impl GenServer
  def handle_cast({:flash, color, sleep_ms}, state) do
    paint_solid(state.spidev, color)

    Process.sleep(sleep_ms)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:next_animation, state) do
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    next = mod(current + 1, num)
    animation_type = Enum.at(animation_types, next)

    {:noreply, set_animation(state, animation_type)}
  end

  @impl GenServer
  def handle_cast(:previous_animation, state) do
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    previous = mod(current - 1, num)
    animation_type = Enum.at(animation_types, previous)

    {:noreply, set_animation(state, animation_type)}
  end

  @impl GenServer
  def handle_cast({:play_animation, animation}, state) do
    {:noreply, %State{state | animation: animation}}
  end

  @impl GenServer
  def handle_call({:play_one_shot, animation, expected_duration}, from, state) do
    current_animation = state.animation
    Process.send_after(self(), {:reply_one_shot, from, current_animation}, expected_duration)
    {:noreply, %State{state | animation: animation}}
  end
end
