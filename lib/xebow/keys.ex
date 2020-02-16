require Logger

defmodule Xebow.Keys do
  use GenServer

  alias Circuits.GPIO

  @gpio_pins %{
    20 => :k001,
    6 => :k002,
    22 => :k003,
    17 => :k004,
    16 => :k005,
    12 => :k006,
    24 => :k007,
    27 => :k008,
    26 => :k009,
    13 => :k010,
    5 => :k011,
    23 => :k012
  }

  # Client

  def start_link([], opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  # Server

  @impl true
  def init([]) do
    pins =
      Enum.map(@gpio_pins, fn {pin_number, _key} ->
        {:ok, pin} = GPIO.open(pin_number, :input, pull_mode: :pullup)
        GPIO.set_interrupts(pin, :both)

        pin
      end)

    {:ok, pins}
  end

  @impl true
  def handle_info({:circuits_gpio, pin_number, _timestamp, value}, state) do
    key_id = @gpio_pins[pin_number]

    case value do
      0 -> Logger.info("#{key_id} pressed!")
      1 -> Logger.info("#{key_id} released!")
    end

    {:noreply, state}
  end
end
