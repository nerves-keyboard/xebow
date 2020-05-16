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

  # pixels on the xebow start in upper left corner and count down instead of
  # across
  @pixels [
    {0, 0},
    {0, 1},
    {0, 2},
    {0, 3},
    {1, 0},
    {1, 1},
    {1, 2},
    {1, 3},
    {2, 0},
    {2, 1},
    {2, 2},
    {2, 3}
  ]

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

  # Server

  @impl true
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
    %State{state | animation: Animation.init_state(animation_type, @pixels)}
  end

  @impl true
  def handle_info(:get_next_state, state) do
    new_animation_state = Animation.next_state(state.animation)

    paint(state.spidev, new_animation_state.pixel_colors)

    Process.send_after(self(), :get_next_state, new_animation_state.delay_ms)

    {:noreply, %State{state | animation: new_animation_state}}
  end

  defp paint(spidev, colors) do
    data =
      Enum.reduce(colors, @sof, fn color, acc ->
        rgb = Chameleon.convert(color, Chameleon.Color.RGB)
        acc <> <<227, rgb.b, rgb.g, rgb.r>>
      end) <> @eof

    SPI.transfer(spidev, data)
  end

  defp paint_solid(spidev, color) do
    color = Chameleon.Keyword.new(color)
    colors = Enum.map(@pixels, fn _ -> color end)
    paint(spidev, colors)
  end

  @impl true
  def handle_cast({:flash, color, sleep_ms}, state) do
    paint_solid(state.spidev, color)

    Process.sleep(sleep_ms)

    {:noreply, state}
  end

  def handle_cast(:next_animation, state) do
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    next = mod(current + 1, num)
    animation_type = Enum.at(animation_types, next)

    {:noreply, set_animation(state, animation_type)}
  end

  def handle_cast(:previous_animation, state) do
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    previous = mod(current - 1, num)
    animation_type = Enum.at(animation_types, previous)

    {:noreply, set_animation(state, animation_type)}
  end
end
