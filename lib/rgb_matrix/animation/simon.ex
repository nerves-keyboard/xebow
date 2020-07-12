defmodule RGBMatrix.Animation.Simon do
  @moduledoc """
  An interactive "Simon" game.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Animation

  use Animation

  defmodule Config do
    @moduledoc false
    use RGBMatrix.Animation.Config
  end

  defmodule State do
    @moduledoc false
    defstruct [:leds, :simon_sequence, :state]
  end

  @black Chameleon.RGB.new(0, 0, 0)
  @red Chameleon.RGB.new(255, 0, 0)

  @impl true
  def new(leds, _config) do
    state =
      %State{leds: leds}
      |> init_sequence()

    {0, state}
  end

  @impl true
  def render(%{state: {:playing_sequence, []}} = state, _config) do
    colors = state.leds |> Enum.map(fn led -> {led.id, @black} end)

    state = %{state | state: {:expecting_input, state.simon_sequence}}

    {:never, colors, state}
  end

  @impl true
  def render(%{state: {:playing_sequence, [{led, color} | rest]}} = state, _config) do
    colors =
      Enum.map(state.leds, fn
        ^led -> {led.id, color}
        other_led -> {other_led.id, @black}
      end)

    state = %{state | state: {:playing_sequence, rest}}

    {1_000, colors, state}
  end

  @impl true
  def render(%{state: {:feedback, [{led, color} | rest]}} = state, _config) do
    colors =
      Enum.map(state.leds, fn
        ^led -> {led.id, color}
        other_led -> {other_led.id, @black}
      end)

    state =
      case rest do
        [] -> extend_sequence(state)
        rest -> %{state | state: {:expecting_input, rest}}
      end

    {500, colors, state}
  end

  @impl true
  def render(%{state: :lost} = state, _config) do
    colors = state.leds |> Enum.map(fn led -> {led.id, @red} end)

    state =
      state
      |> init_sequence()

    {2_000, colors, state}
  end

  @impl true
  def render(state, _config) do
    colors = state.leds |> Enum.map(fn led -> {led.id, @black} end)

    {:never, colors, state}
  end

  @impl true
  def interact(
        %{state: {:expecting_input, [{led, _color} | _rest] = sequence}} = state,
        _config,
        led
      ) do
    state = %{state | state: {:feedback, sequence}}

    {0, state}
  end

  @impl true
  def interact(%{state: {:expecting_input, [_x | _rest]}} = state, _config, _y) do
    state = %{state | state: :lost}

    {0, state}
  end

  @impl true
  def interact(state, _config, _led) do
    {:ignore, state}
  end

  defp random_color do
    HSV.new((:rand.uniform() * 360) |> trunc(), 100, 100)
  end

  defp init_sequence(state) do
    led = Enum.random(state.leds)
    color = random_color()
    %State{state | simon_sequence: [{led, color}], state: {:playing_sequence, [{led, color}]}}
  end

  defp extend_sequence(state) do
    led = Enum.random(state.leds)
    color = random_color()
    sequence = state.simon_sequence ++ [{led, color}]

    %{
      state
      | simon_sequence: sequence,
        state: {:playing_sequence, sequence}
    }
  end
end
