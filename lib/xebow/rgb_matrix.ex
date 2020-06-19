defmodule Xebow.RGBMatrix do
  @behaviour Xebow.Paintable

  use GenServer

  alias Circuits.SPI

  defmodule State do
    @moduledoc false
    defstruct [:spidev]
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


  @impl Xebow.Paintable
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
