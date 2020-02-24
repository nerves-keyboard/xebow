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

  @hid_device "/dev/hidg0"

  @keymap [
    # Layer 0:
    %{
      k001: AFK.Keycode.Key.new(:"7"),
      k002: AFK.Keycode.Key.new(:"4"),
      k003: AFK.Keycode.Key.new(:"1"),
      k004: AFK.Keycode.Key.new(:"0"),
      k005: AFK.Keycode.Key.new(:"8"),
      k006: AFK.Keycode.Key.new(:"5"),
      k007: AFK.Keycode.Key.new(:"2"),
      k008: AFK.Keycode.Layer.new(:hold, 1),
      k009: AFK.Keycode.Key.new(:"9"),
      k010: AFK.Keycode.Key.new(:"6"),
      k011: AFK.Keycode.Key.new(:"3"),
      k012: AFK.Keycode.Layer.new(:hold, 2)
    },
    # Layer 1:
    %{
      k001: AFK.Keycode.Transparent.new(),
      k002: AFK.Keycode.Transparent.new(),
      k003: AFK.Keycode.Transparent.new(),
      k004: AFK.Keycode.Transparent.new(),
      k005: AFK.Keycode.Key.new(:mute),
      k006: AFK.Keycode.Transparent.new(),
      k007: AFK.Keycode.Transparent.new(),
      k008: AFK.Keycode.None.new(),
      k009: AFK.Keycode.Key.new(:volume_up),
      k010: AFK.Keycode.Key.new(:volume_down),
      k011: AFK.Keycode.Transparent.new(),
      k012: AFK.Keycode.Transparent.new()
    },
    # Layer 2:
    %{
      k001: AFK.Keycode.MFA.new({__MODULE__, :flash_red, []}),
      k002: AFK.Keycode.MFA.new({__MODULE__, :previous_animation, []}),
      k003: AFK.Keycode.Transparent.new(),
      k004: AFK.Keycode.Transparent.new(),
      k005: AFK.Keycode.Transparent.new(),
      k006: AFK.Keycode.Transparent.new(),
      k007: AFK.Keycode.Transparent.new(),
      k008: AFK.Keycode.Transparent.new(),
      k009: AFK.Keycode.MFA.new({__MODULE__, :flash_green, []}),
      k010: AFK.Keycode.MFA.new({__MODULE__, :next_animation, []}),
      k011: AFK.Keycode.Transparent.new(),
      k012: AFK.Keycode.Transparent.new()
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

    {:ok, keyboard_state} =
      AFK.State.start_link(
        keymap: @keymap,
        event_receiver: self(),
        hid_report_mod: AFK.HIDReport.SixKeyRollover
      )

    {:ok,
     %{
       pins: pins,
       keyboard_state: keyboard_state,
       hid: hid,
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

  def handle_info({:hid_report, hid_report}, state) do
    IO.binwrite(state.hid, hid_report)
    {:noreply, state}
  end

  defp handle_gpio_interrupt({pin_number, value}, state) do
    key_id = @gpio_pins[pin_number]

    case value do
      0 ->
        Logger.debug("key pressed #{key_id}")
        AFK.State.press_key(state.keyboard_state, key_id)

      1 ->
        Logger.debug("key released #{key_id}")
        AFK.State.release_key(state.keyboard_state, key_id)
    end

    {:noreply, state}
  end

  # Custom Key Functions

  def flash_red do
    Xebow.RGBMatrix.flash("red")
  end

  def flash_green do
    Xebow.RGBMatrix.flash("green")
  end

  def next_animation do
    Xebow.RGBMatrix.next_animation()
  end

  def previous_animation do
    Xebow.RGBMatrix.previous_animation()
  end

  def start_wifi_wizard do
    case VintageNetWizard.run_wizard() do
      :ok -> Xebow.RGBMatrix.flash("green")
      {:error, _reason} -> Xebow.RGBMatrix.flash("red")
    end
  end
end
