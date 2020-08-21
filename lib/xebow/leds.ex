defmodule Xebow.LEDs do
  @moduledoc """
  GenServer that interacts with the SPI device that controls the RGB LEDs on the
  Keybow.

  It registers itself to RGBMatrix.Engine on init so the animations can be
  painted onto the keybow's RGB LEDs.
  """

  if Mix.target() == :host,
    do: @compile({:no_warn_undefined, Circuits.SPI})

  use GenServer

  alias Circuits.SPI
  alias RGBMatrix.Engine

  defmodule State do
    @moduledoc false
    defstruct [:spidev, :paint_fn]
  end

  @spi_device "spidev0.0"
  @spi_speed_hz 4_000_000
  @sof <<0, 0, 0, 0>>
  @eof <<255, 255, 255, 255>>
  # This is the hardware order that the LED colors need to be sent to the SPI
  # device in. The LED IDs are the ones from `Xebow.layout/0`.
  @spi_led_order [
    :l001,
    :l004,
    :l007,
    :l010,
    :l002,
    :l005,
    :l008,
    :l011,
    :l003,
    :l006,
    :l009,
    :l012
  ]

  # Client

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server

  @impl GenServer
  def init([]) do
    {:ok, spidev} =
      SPI.open(@spi_device,
        speed_hz: @spi_speed_hz
      )

    paint_fn = register_with_engine!(spidev)

    state = %State{spidev: spidev, paint_fn: paint_fn}

    {:ok, state}
  end

  defp register_with_engine!(spidev) do
    pid = self()

    {:ok, paint_fn, _frame} =
      Engine.register_paintable(fn frame ->
        if Process.alive?(pid) do
          paint(spidev, frame)
          :ok
        else
          :unregister
        end
      end)

    paint_fn
  end

  defp paint(spidev, frame) do
    colors =
      @spi_led_order
      |> Enum.map(&Map.fetch!(frame, &1))

    data =
      Enum.reduce(colors, @sof, fn color, acc ->
        rgb = Chameleon.convert(color, Chameleon.Color.RGB)
        acc <> <<227, rgb.b, rgb.g, rgb.r>>
      end) <> @eof

    SPI.transfer(spidev, data)
  end

  @impl GenServer
  def terminate(_reason, state) do
    SPI.close(state.spidev)
    Engine.unregister_paintable(state.paint_fn)
  end
end
