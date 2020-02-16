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

  @hid_device "/dev/hidg0"

  @keymap [
    %{
      k001: AFK.Keycode.Key.new(:"7"),
      k002: AFK.Keycode.Key.new(:"4"),
      k003: AFK.Keycode.Key.new(:"1"),
      k004: AFK.Keycode.Key.new(:"0"),
      k005: AFK.Keycode.Key.new(:"8"),
      k006: AFK.Keycode.Key.new(:"5"),
      k007: AFK.Keycode.Key.new(:"2"),
      k008: AFK.Keycode.Key.new(:l),
      k009: AFK.Keycode.Key.new(:"9"),
      k010: AFK.Keycode.Key.new(:"6"),
      k011: AFK.Keycode.Key.new(:"3"),
      k012: AFK.Keycode.Key.new(:o)
    }
  ]

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

    hid = File.open!(@hid_device, [:write])

    {:ok,
     %{
       pins: pins,
       keyboard_state: AFK.State.new(@keymap),
       hid: hid,
       previous_hid_report: <<0, 0, 0, 0, 0, 0, 0, 0>>,
       # The above `set_interrupts` will send an initial event (in this case a
       # 'release' event).
       # We need to keep track of which ones we haven't seen yet so we can
       # ignore them.
       init_releases_pending: @gpio_pins |> Map.keys() |> MapSet.new()
     }}
  end

  @impl true
  def handle_info(
        {:circuits_gpio, pin_number, _timestamp, value},
        %{init_releases_pending: _} = state
      ) do
    # ignore initial release events, process others
    if MapSet.member?(state.init_releases_pending, pin_number) do
      new_pending = MapSet.delete(state.init_releases_pending, pin_number)

      if MapSet.size(new_pending) == 0 do
        {:noreply, Map.delete(state, :init_releases_pending)}
      else
        {:noreply, %{state | init_releases_pending: new_pending}}
      end
    else
      handle_gpio_interrupt({pin_number, value}, state)
    end
  end

  def handle_info({:circuits_gpio, pin_number, _timestamp, value}, state) do
    handle_gpio_interrupt({pin_number, value}, state)
  end

  defp handle_gpio_interrupt({pin_number, value}, state) do
    key_id = @gpio_pins[pin_number]

    new_keyboard_state =
      case value do
        0 -> AFK.State.press_key(state.keyboard_state, key_id)
        1 -> AFK.State.release_key(state.keyboard_state, key_id)
      end

    hid_report = AFK.HIDReport.SixKeyRollover.hid_report(new_keyboard_state)

    if hid_report != state.previous_hid_report do
      IO.binwrite(state.hid, hid_report)
    end

    {:noreply, %{state | keyboard_state: new_keyboard_state, previous_hid_report: hid_report}}
  end
end
