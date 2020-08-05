defmodule RGBMatrix.Animation.SolidReactive do
  @moduledoc """
  Static single hue, pulses keys hit to shifted hue then fades to current hue.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Animation

  use Animation

  import RGBMatrix.Utils, only: [mod: 2]

  field :speed, :integer,
    default: 4,
    min: 0,
    max: 32,
    doc: [
      name: "Speed",
      description: """
      The speed at which the hue shifts back to base.
      """
    ]

  field :distance, :integer,
    default: 180,
    min: 0,
    max: 360,
    step: 10,
    doc: [
      name: "Distance",
      description: """
      The distance that the hue shifts on key-press.
      """
    ]

  field :direction, :option,
    default: :random,
    options: [
      :random,
      :negative,
      :positive
    ],
    doc: [
      name: "Direction",
      description: """
      The direction (through the color wheel) that the hue shifts on key-press.
      """
    ]

  defmodule State do
    @moduledoc false
    defstruct [:first_render, :paused, :tick, :color, :leds, :hits]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    color = HSV.new(190, 100, 100)
    %State{first_render: true, paused: false, tick: 0, color: color, leds: leds, hits: %{}}
  end

  @impl true
  def render(%{first_render: true} = state, _config) do
    %{color: color, leds: leds} = state

    colors = Enum.map(leds, &{&1.id, color})

    {:never, colors, %{state | first_render: false, paused: true}}
  end

  def render(%{paused: true} = state, _config),
    do: {:never, [], state}

  def render(state, config) do
    %{tick: tick, color: color, leds: leds, hits: hits} = state
    %{speed: _speed, distance: distance} = config

    colors =
      Enum.map(leds, fn
        led when is_map_key(hits, led) ->
          {hit_tick, direction_modifier} = hits[led]

          if tick - hit_tick >= distance do
            {led.id, color}
          else
            hue_shift = (tick - hit_tick - distance) * direction_modifier
            hue = mod(color.h + hue_shift, 360)
            {led.id, HSV.new(hue, color.s, color.v)}
          end

        led ->
          {led.id, color}
      end)

    updated_hits =
      hits
      |> Enum.reject(fn {_led, {hit_tick, _direction_modifier}} ->
        tick - hit_tick >= distance
      end)
      |> Enum.into(%{})

    state = %{
      state
      | tick: tick + 1,
        hits: updated_hits,
        paused: updated_hits == %{}
    }

    {@delay_ms, colors, state}
  end

  @impl true
  def interact(state, config, led) do
    direction = direction_modifier(config.direction)

    render_in =
      case state.paused do
        true -> 0
        false -> :ignore
      end

    {render_in, %{state | paused: false, hits: Map.put(state.hits, led, {state.tick, direction})}}
  end

  defp direction_modifier(:random), do: Enum.random([-1, 1])
  defp direction_modifier(:negative), do: -1
  defp direction_modifier(:positive), do: 1
end
