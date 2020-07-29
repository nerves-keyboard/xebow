require Logger

defmodule Xebow.Keyboard do
  @moduledoc """
  Keyboard GenServer for handling key events.

  This module implements three pieces of functionality (and should maybe be
  broken out into sub-modules):

  1. Interacts with the GPIO pins on the raspberry pi to detect physical key
     press and key release events.
  2. Uses AFK to turn those physical key presses and releases into HID events.
  3. Writes the HID events to the linux HID file device that was set up by
     `Xebow.HIDGadget`
  """

  if Mix.target() == :host,
    do: @compile({:no_warn_undefined, Circuits.GPIO})

  use GenServer

  alias Circuits.GPIO
  alias RGBMatrix.Engine

  # maps the physical GPIO pins to key IDs
  @gpio_pins %{
    6 => :k004,
    5 => :k009,
    27 => :k011,
    26 => :k003,
    24 => :k008,
    23 => :k012,
    22 => :k007,
    20 => :k001,
    17 => :k010,
    16 => :k002,
    13 => :k006,
    12 => :k005
  }

  # this file exists because `Xebow.HIDGadget` set it up during boot.
  @hid_device "/dev/hidg0"

  @keymap [
    # Layer 0:
    %{
      k001: AFK.Keycode.Key.new(:"7"),
      k002: AFK.Keycode.Key.new(:"8"),
      k003: AFK.Keycode.Key.new(:"9"),
      k004: AFK.Keycode.Key.new(:"4"),
      k005: AFK.Keycode.Key.new(:"5"),
      k006: AFK.Keycode.Key.new(:"6"),
      k007: AFK.Keycode.Key.new(:"1"),
      k008: AFK.Keycode.Key.new(:"2"),
      k009: AFK.Keycode.Key.new(:"3"),
      k010: AFK.Keycode.Key.new(:"0"),
      k011: AFK.Keycode.Layer.new(:hold, 1),
      k012: AFK.Keycode.Layer.new(:hold, 2)
    },
    # Layer 1:
    %{
      k001: AFK.Keycode.Transparent.new(),
      k002: AFK.Keycode.Key.new(:mute),
      k003: AFK.Keycode.Key.new(:volume_up),
      k004: AFK.Keycode.Transparent.new(),
      k005: AFK.Keycode.Transparent.new(),
      k006: AFK.Keycode.Key.new(:volume_down),
      k007: AFK.Keycode.Transparent.new(),
      k008: AFK.Keycode.Transparent.new(),
      k009: AFK.Keycode.Transparent.new(),
      k010: AFK.Keycode.Transparent.new(),
      k011: AFK.Keycode.None.new(),
      k012: AFK.Keycode.Transparent.new()
    },
    # Layer 2:
    %{
      k001: AFK.Keycode.MFA.new({__MODULE__, :flash, ["red"]}),
      k002: AFK.Keycode.Transparent.new(),
      k003: AFK.Keycode.MFA.new({__MODULE__, :flash, ["green"]}),
      k004: AFK.Keycode.MFA.new({__MODULE__, :previous_animation, []}),
      k005: AFK.Keycode.Transparent.new(),
      k006: AFK.Keycode.MFA.new({__MODULE__, :next_animation, []}),
      k007: AFK.Keycode.Transparent.new(),
      k008: AFK.Keycode.Transparent.new(),
      k009: AFK.Keycode.Transparent.new(),
      k010: AFK.Keycode.Transparent.new(),
      k011: AFK.Keycode.Transparent.new(),
      k012: AFK.Keycode.Transparent.new()
    }
  ]

  # Client

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Cycle to the next animation
  """
  @spec next_animation() :: :ok
  def next_animation do
    Xebow.next_animation()
  end

  @doc """
  Cycle to the previous animation
  """
  @spec previous_animation() :: :ok
  def previous_animation do
    Xebow.previous_animation()
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

    state = %{
      pins: pins,
      keyboard_state: keyboard_state,
      hid: hid,
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:hid_report, hid_report}, state) do
    IO.binwrite(state.hid, hid_report)
    {:noreply, state}
  end

  @impl GenServer
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
        rgb_matrix_interact(key_id)

      1 ->
        Logger.debug("key released #{key_id}")
        AFK.State.release_key(keyboard_state, key_id)
    end
  end

  defp rgb_matrix_interact(key_id) do
    case Layout.led_for_key(Xebow.layout(), key_id) do
      nil -> :noop
      led -> Engine.interact(led)
    end
  end

  # Custom Key Functions

  def flash(color) do
    Logger.info("TODO: flash color #{inspect(color)}")
  end
end
