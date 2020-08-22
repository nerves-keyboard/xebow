require Logger

defmodule Xebow.Excalibur.Keyboard do
  use GenServer

  alias Circuits.GPIO
  alias Xebow.Excalibur.Utils

  @matrix_layout [
    [:k001, :k002, :k003, :k004, :k005, :k006, :k007, :k008, :k009],
    [:k010, :k011, :k012, :k013, :k014, :k015, :k016, :k017, :k018],
    [:k019, :k020, :k021, :k022, :k023, :k024, :k025, :k026, :k027],
    [:k028, :k029, :k030, :k031, :k032, :k033, :k034, :k035, :k036],
    [:k037, :k038, :k039, :k040, :k041, :k042, :k043, :k044, :k045],
    [:k046, :k047, :k048, :k049, :k050, :k051, :k052, :k053, :k054],
    [:k055, :k056, :k057, :k058, :k059, :k060, :k061, :k062, :k063],
    [:k064, :k065, :k066, :k067, :k068]
  ]

  @row_pin [21, 20, 14, 15, 18, 27, 23, 24]
  @col_pins [10, 25, 8, 7, 1, 12, 16, 3, 2]

  @debounce_window 10

  # this file exists because `Xebow.HIDGadget` set it up during boot.
  @hid_device "/dev/hidg0"

  @keymap [
    # Layer 0:
    %{
      k001: AFK.Keycode.Key.new(:escape),
      k002: AFK.Keycode.Key.new(:"1"),
      k003: AFK.Keycode.Key.new(:"2"),
      k004: AFK.Keycode.Key.new(:"3"),
      k005: AFK.Keycode.Key.new(:"4"),
      k006: AFK.Keycode.Key.new(:"5"),
      k007: AFK.Keycode.Key.new(:"6"),
      k008: AFK.Keycode.Key.new(:"7"),
      k009: AFK.Keycode.Key.new(:"8"),
      k010: AFK.Keycode.Key.new(:"9"),
      k011: AFK.Keycode.Key.new(:"0"),
      k012: AFK.Keycode.Key.new(:minus),
      k013: AFK.Keycode.Key.new(:equals),
      k014: AFK.Keycode.Key.new(:backspace),
      k015: AFK.Keycode.Key.new(:home),
      k016: AFK.Keycode.Key.new(:page_up),
      #
      k017: AFK.Keycode.Key.new(:tab),
      k018: AFK.Keycode.Key.new(:q),
      k019: AFK.Keycode.Key.new(:w),
      k020: AFK.Keycode.Key.new(:e),
      k021: AFK.Keycode.Key.new(:r),
      k022: AFK.Keycode.Key.new(:t),
      k023: AFK.Keycode.Key.new(:y),
      k024: AFK.Keycode.Key.new(:u),
      k025: AFK.Keycode.Key.new(:i),
      k026: AFK.Keycode.Key.new(:o),
      k027: AFK.Keycode.Key.new(:p),
      k028: AFK.Keycode.Key.new(:left_square_bracket),
      k029: AFK.Keycode.Key.new(:right_square_bracket),
      k030: AFK.Keycode.Key.new(:backslash),
      k031: AFK.Keycode.Key.new(:end),
      k032: AFK.Keycode.Key.new(:page_down),
      #
      k033: AFK.Keycode.Key.new(:caps_lock),
      k034: AFK.Keycode.Key.new(:a),
      k035: AFK.Keycode.Key.new(:s),
      k036: AFK.Keycode.Key.new(:d),
      k037: AFK.Keycode.Key.new(:f),
      k038: AFK.Keycode.Key.new(:g),
      k039: AFK.Keycode.Key.new(:h),
      k040: AFK.Keycode.Key.new(:j),
      k041: AFK.Keycode.Key.new(:k),
      k042: AFK.Keycode.Key.new(:l),
      k043: AFK.Keycode.Key.new(:semicolon),
      k044: AFK.Keycode.Key.new(:single_quote),
      k045: AFK.Keycode.Key.new(:enter),
      #
      k046: AFK.Keycode.Modifier.new(:left_shift),
      k047: AFK.Keycode.Key.new(:z),
      k048: AFK.Keycode.Key.new(:x),
      k049: AFK.Keycode.Key.new(:c),
      k050: AFK.Keycode.Key.new(:v),
      k051: AFK.Keycode.Key.new(:b),
      k052: AFK.Keycode.Key.new(:n),
      k053: AFK.Keycode.Key.new(:m),
      k054: AFK.Keycode.Key.new(:comma),
      k055: AFK.Keycode.Key.new(:period),
      k056: AFK.Keycode.Key.new(:slash),
      k057: AFK.Keycode.Modifier.new(:right_shift),
      k058: AFK.Keycode.Key.new(:up),
      #
      k059: AFK.Keycode.Modifier.new(:left_control),
      k060: AFK.Keycode.Modifier.new(:left_super),
      k061: AFK.Keycode.Modifier.new(:left_alt),
      k062: AFK.Keycode.Key.new(:space),
      k063: AFK.Keycode.Modifier.new(:right_alt),
      k064: AFK.Keycode.Layer.new(:hold, 1),
      k065: AFK.Keycode.Modifier.new(:right_control),
      k066: AFK.Keycode.Key.new(:left),
      k067: AFK.Keycode.Key.new(:down),
      k068: AFK.Keycode.Key.new(:right)
    },
    # Layer 0:
    %{
      k001: AFK.Keycode.Key.new(:grave),
      k031: AFK.Keycode.Key.new(:delete)
    }
  ]

  # Client

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def reset! do
    GenServer.call(__MODULE__, :reset!)
  end

  # Server

  @impl true
  def init([]) do
    {:ok, keyboard_state} =
      AFK.State.start_link(
        keymap: @keymap,
        event_receiver: self(),
        hid_report_mod: AFK.HIDReport.SixKeyRollover
      )

    state = %{
      buffer: [],
      held_keys: [],
      matrix_config: init_matrix_config(),
      timer: nil,
      hid: File.open!(@hid_device, [:write]),
      keyboard_state: keyboard_state
    }

    send(self(), :scan)

    {:ok, state}
  end

  @impl true
  def handle_call(:reset!, _from, state) do
    case state.timer do
      nil -> :ok
      timer -> Process.cancel_timer(timer)
    end

    state = %{state | buffer: [], held_keys: [], timer: nil}

    {:reply, :ok, state}
  end

  defp init_matrix_config do
    # transpose matrix, because we need to scan by column, not by row
    matrix_layout =
      @matrix_layout
      |> Utils.pad_matrix()
      |> Enum.zip()
      |> Enum.map(fn col ->
        col
        |> Tuple.to_list()
        |> Enum.filter(& &1)
      end)

    # open the pins
    row_pins = @row_pin |> Enum.map(&open_input_pin!/1)
    col_pins = @col_pins |> Enum.map(&open_output_pin!/1)

    # zip the open pin resources into the matrix structure
    Enum.zip(
      col_pins,
      Enum.map(matrix_layout, fn col ->
        Enum.zip(row_pins, col)
      end)
    )
  end

  defp open_input_pin!(pin_number) do
    # clear any stuck pins
    {:ok, pin} = GPIO.open(pin_number, :output, initial_value: 0)
    :ok = GPIO.write(pin, 0)
    :ok = GPIO.close(pin)

    {:ok, pin} = GPIO.open(pin_number, :input, pull_mode: :pulldown, initial_value: 0)
    pin
  end

  defp open_output_pin!(pin_number) do
    {:ok, pin} = GPIO.open(pin_number, :output, initial_value: 0)
    pin
  end

  @impl true
  def handle_info(:flush, state) do
    state.buffer
    |> Enum.reverse()
    |> Utils.dedupe_events()
    |> Enum.each(fn
      {:pressed, key_id} ->
        Logger.debug(fn -> "Key pressed: #{key_id}" end)
        AFK.State.press_key(state.keyboard_state, key_id)

      {:released, key_id} ->
        Logger.debug(fn -> "Key released: #{key_id}" end)
        AFK.State.release_key(state.keyboard_state, key_id)
    end)

    {:noreply, %{state | buffer: [], timer: nil}}
  end

  @impl true
  def handle_info(:scan, state) do
    keys = scan(state.matrix_config)

    released = state.held_keys -- keys
    pressed = keys -- state.held_keys

    buffer = Enum.reduce(released, state.buffer, fn key, acc -> [{:released, key} | acc] end)
    buffer = Enum.reduce(pressed, buffer, fn key, acc -> [{:pressed, key} | acc] end)

    state =
      if buffer != state.buffer do
        set_debounce_timer(state)
      else
        state
      end

    Process.send_after(self(), :scan, 2)

    {:noreply, %{state | held_keys: keys, buffer: buffer}}
  end

  @impl GenServer
  def handle_info({:hid_report, hid_report}, state) do
    IO.binwrite(state.hid, hid_report)
    {:noreply, state}
  end

  defp scan(matrix_config) do
    Enum.reduce(matrix_config, [], fn {col_pin, rows}, acc ->
      with_pin_high(col_pin, fn ->
        Enum.reduce(rows, acc, fn {row_pin, key_id}, acc ->
          case pin_high?(row_pin) do
            true -> [key_id | acc]
            false -> acc
          end
        end)
      end)
    end)
  end

  defp with_pin_high(pin, fun) do
    :ok = GPIO.write(pin, 1)
    response = fun.()
    :ok = GPIO.write(pin, 0)
    response
  end

  defp pin_high?(pin) do
    GPIO.read(pin) == 1
  end

  defp set_debounce_timer(%{timer: nil} = state) do
    %{state | timer: Process.send_after(self(), :flush, @debounce_window)}
  end

  defp set_debounce_timer(%{timer: timer} = state) do
    Process.cancel_timer(timer)
    set_debounce_timer(%{state | timer: nil})
  end
end
