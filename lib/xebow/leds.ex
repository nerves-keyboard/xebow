defmodule Xebow.LEDs do
  @moduledoc """
  GenServer that interacts with the SPI device that controls the RGB LEDs on the
  Keybow.

  It also implements the RGBMatrix.Paintable behavior so that the RGBMatrix
  effects can be painted onto the keybow's RGB LEDs.
  """

  @behaviour RGBMatrix.Paintable

  use GenServer

  alias Circuits.SPI

  defmodule State do
    @moduledoc false
    defstruct [:spidev]
  end

  @spi_device "spidev0.0"
  @spi_speed_hz 4_000_000
  @sof <<0, 0, 0, 0>>
  @eof <<255, 255, 255, 255>>

  # Client

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl RGBMatrix.Paintable
  def get_paint_fn do
    GenServer.call(__MODULE__, :get_paint_fn)
  end

  # Server

  @impl GenServer
  def init([]) do
    {:ok, spidev} =
      SPI.open(@spi_device,
        speed_hz: @spi_speed_hz
      )

    state = %State{spidev: spidev}

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_paint_fn, _from, state) do
    paint_fn = fn frame -> paint(state.spidev, frame) end
    {:reply, paint_fn, state}
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
end
