require Logger

defmodule Xebow.Keys do
  use GenServer

  alias Circuits.GPIO
  alias Xebow.{Animation, Frame}

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
      k001: AFK.Keycode.MFA.new({__MODULE__, :flash, ["red"]}),
      k002: AFK.Keycode.MFA.new({__MODULE__, :previous_animation, []}),
      k003: AFK.Keycode.Transparent.new(),
      k004: AFK.Keycode.Transparent.new(),
      k005: AFK.Keycode.Transparent.new(),
      k006: AFK.Keycode.Transparent.new(),
      k007: AFK.Keycode.Transparent.new(),
      k008: AFK.Keycode.Transparent.new(),
      k009: AFK.Keycode.MFA.new({__MODULE__, :flash, ["green"]}),
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
        {:ok, pin_ref} = GPIO.open(pin_number, :input, pull_mode: :pullup)
        # Don't read because the initial value might be garbage
        value = 1

        {pin_number, pin_ref, value}
      end)

    hid = File.open!(@hid_device, [:write])

    {:ok, keyboard_state} =
      AFK.State.start_link(
        keymap: @keymap,
        event_receiver: self(),
        hid_report_mod: AFK.HIDReport.SixKeyRollover
      )

    poll_timer_ms = 15
    :timer.send_interval(poll_timer_ms, self(), :update_pin_values)

    {:ok,
     %{
       pins: pins,
       keyboard_state: keyboard_state,
       hid: hid
     }}
  end

  @impl GenServer
  def handle_info({:hid_report, hid_report}, state) do
    IO.binwrite(state.hid, hid_report)
    {:noreply, state}
  end

  def handle_info(:update_pin_values, state) do
    new_pins =
      Enum.map(state.pins, fn {pin_number, pin_ref, old_value} ->
        new_value = GPIO.read(pin_ref)

        if old_value != new_value do
          handle_gpio_interrupt(pin_number, new_value, state.keyboard_state)
        end

        {pin_number, pin_ref, new_value}
      end)

    state = %{state | pins: new_pins}
    {:noreply, state}
  end

  defp handle_gpio_interrupt(pin_number, value, keyboard_state) do
    key_id = @gpio_pins[pin_number]

    case value do
      0 ->
        Logger.debug("key pressed #{key_id}")
        AFK.State.press_key(keyboard_state, key_id)

      1 ->
        Logger.debug("key released #{key_id}")
        AFK.State.release_key(keyboard_state, key_id)
    end
  end

  # Custom Key Functions

  def flash(color) do
    pixels = Xebow.Utils.pixels()
    color = Chameleon.Keyword.new(color)
    frame = Frame.solid_color(pixels, color)

    animation = Animation.new(type: Animation.Static, frames: [frame], delay_ms: 250, loop: 1)

    Xebow.Engine.play_animation(animation, async: false)
  end

  def next_animation do
    Xebow.Engine.next_animation()
  end

  def previous_animation do
    Xebow.Engine.previous_animation()
  end

  def start_wifi_wizard do
    case VintageNetWizard.run_wizard() do
      :ok -> flash("green")
      {:error, _reason} -> flash("red")
    end
  end
end
