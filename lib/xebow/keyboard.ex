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

  use GenServer

  alias Circuits.GPIO
  alias RGBMatrix.{Animation, Frame}

  # maps the physical GPIO pins to key IDs
  # TODO: re-number these keys so they map to the keyboard in X/Y natural order,
  # rather than keybow hardware order.
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

  # this file exists because `Xebow.HIDGadget` set it up during boot.
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

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Cycle to the next animation
  """
  @spec next_animation() :: :ok
  def next_animation do
    GenServer.cast(__MODULE__, :next_animation)
  end

  @doc """
  Cycle to the previous animation
  """
  @spec previous_animation() :: :ok
  def previous_animation do
    GenServer.cast(__MODULE__, :previous_animation)
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

    animations =
      Animation.types()
      |> Enum.map(&Animation.new(type: &1))

    {:ok,
     %{
       pins: pins,
       keyboard_state: keyboard_state,
       hid: hid,
       animations: animations,
       current_animation_index: 0
     }}
  end

  @impl GenServer
  def handle_cast(:next_animation, state) do
    next_index = state.current_animation_index + 1

    next_index =
      case next_index < Enum.count(state.animations) do
        true -> next_index
        _ -> 0
      end

    animation = Enum.at(state.animations, next_index)

    RGBMatrix.Engine.play_animation(animation)

    state = %{state | current_animation_index: next_index}

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:previous_animation, state) do
    previous_index = state.current_animation_index - 1

    previous_index =
      case previous_index < 0 do
        true -> Enum.count(state.animations) - 1
        _ -> previous_index
      end

    animation = Enum.at(state.animations, previous_index)

    RGBMatrix.Engine.play_animation(animation)

    state = %{state | current_animation_index: previous_index}

    {:noreply, state}
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

    RGBMatrix.Engine.play_animation(animation, async: false)
  end
end
