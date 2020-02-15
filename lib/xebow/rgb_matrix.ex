defmodule Xebow.RGBMatrix do
  use GenServer

  alias Circuits.SPI
  alias Xebow.RGBMatrix.Animations

  @type coordinate :: non_neg_integer
  @type tick :: non_neg_integer
  @type color :: any

  @spi_device "spidev0.0"
  @spi_speed_hz 4_000_000
  @sof <<0, 0, 0, 0>>
  @eof <<255, 255, 255, 255>>

  @rows 4
  @cols 3

  # approximates ~60 FPS
  @delay_ms 17

  # Client

  def start_link([], opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  # Server

  @impl true
  def init([]) do
    {:ok, spidev} =
      SPI.open(@spi_device,
        speed_hz: @spi_speed_hz
      )

    Process.send_after(self(), :tick, @delay_ms)

    {:ok,
     %{
       animation: Animations.animations() |> hd(),
       spidev: spidev,
       tick: 0
     }}
  end

  @impl true
  def handle_info(:tick, %{tick: tick} = state) do
    colors =
      for x <- 0..(@cols - 1),
          y <- 0..(@rows - 1) do
        state.animation.run(x, y, tick)
      end

    paint(state.spidev, colors)

    Process.send_after(self(), :tick, @delay_ms)

    {:noreply, %{state | tick: tick + 1}}
  end

  defp paint(spidev, colors) do
    data =
      Enum.reduce(colors, @sof, fn color, acc ->
        rgb = Chameleon.convert(color, Chameleon.Color.RGB)
        acc <> <<227, rgb.b, rgb.g, rgb.r>>
      end) <> @eof

    SPI.transfer(spidev, data)
  end
end
