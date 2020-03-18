require Logger

defmodule Xebow.Matrix do
  use GenServer

  alias Circuits.GPIO
  alias Xebow.Utils

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
    state = %{
      buffer: [],
      held_keys: [],
      matrix_config: init_matrix_config(),
      timer: nil
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
      {:pressed, key} ->
        Logger.debug(fn -> "Key pressed: #{key}" end)

      # KeyboardServer.key_pressed(key)

      {:released, key} ->
        Logger.debug(fn -> "Key released: #{key}" end)
        # KeyboardServer.key_released(key)
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
