defmodule Xebow.RGBMatrix do
  use GenServer

  alias Circuits.SPI
  alias Xebow.RGBMatrix.Animations

  import Xebow.Utils, only: [mod: 2]

  @type coordinate :: non_neg_integer
  @type tick :: non_neg_integer
  @type color :: any

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

  def flash(color) do
    GenServer.cast(__MODULE__, {:flash, color})
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

    Process.send_after(self(), :run, 0)

    initial_animation = Animations.animations() |> hd()

    state = set_animation(%{spidev: spidev}, initial_animation)

    {:ok, state}
  end

  defp set_animation(state, animation) do
    state
    |> Map.put(:animation, animation)
    |> Map.put(:animation_state, animation.init())
  end

  @impl true
  def handle_info(:run, state) do
    {colors, delay, new_animation_state} = state.animation.run(@pixels, state.animation_state)

    paint(state.spidev, colors)

    Process.send_after(self(), :run, delay)

    {:noreply, %{state | animation_state: new_animation_state}}
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
    colors = for _ <- 1..12, do: color
    paint(spidev, colors)
  end

  @impl true
  def handle_cast({:flash, color}, state) do
    paint_solid(state.spidev, color)

    Process.sleep(250)

    {:noreply, state}
  end

  def handle_cast(:next_animation, state) do
    animations = Animations.animations()
    num = Enum.count(animations)
    current = Enum.find_index(animations, &(&1 == state.animation))
    next = mod(current + 1, num)
    animation = Enum.at(animations, next)

    {:noreply, set_animation(state, animation)}
  end

  def handle_cast(:previous_animation, state) do
    animations = Animations.animations()
    num = Enum.count(animations)
    current = Enum.find_index(animations, &(&1 == state.animation))
    previous = mod(current - 1, num)
    animation = Enum.at(animations, previous)

    {:noreply, set_animation(state, animation)}
  end
end
