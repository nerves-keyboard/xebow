defmodule RGBMatrix.Animation.HueWave do
  @moduledoc """
  Creates a wave of shifting hue that moves across the matrix.
  """

  alias Chameleon.HSV
  alias Layout.LED
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
      Controls the speed at which the wave moves across the matrix.
      """
    ]

  field :width, :integer,
    default: 20,
    min: 10,
    max: 100,
    step: 10,
    doc: [
      name: "Width",
      description: """
      The rate of change of the wave, higher values means it's more spread out.
      """
    ]

  field :direction, :option,
    default: :right,
    options: [
      :right,
      :left,
      :up,
      :down
    ],
    doc: [
      name: "Direction",
      description: """
      The direction the wave travels across the matrix.
      """
    ]

  defmodule State do
    @moduledoc false
    defstruct [:tick, :leds, :steps]
  end

  @delay_ms 17

  @impl true
  def new(leds, config) do
    steps = 360 / config.width
    {0, %State{tick: 0, leds: leds, steps: steps}}
  end

  @impl true
  def render(state, config) do
    %{tick: tick, leds: leds, steps: _steps} = state
    %{speed: speed, direction: direction} = config

    steps = 360 / config.width

    time = div(tick * speed, 5)

    colors = render_colors(leds, steps, time, direction)

    {@delay_ms, colors, %{state | tick: tick + 1}}
  end

  defp render_colors(leds, steps, time, :right) do
    for %LED{id: id, x: x} <- leds do
      hue = mod(trunc(x * steps) - time, 360)
      {id, HSV.new(hue, 100, 100)}
    end
  end

  defp render_colors(leds, steps, time, :left) do
    for %LED{id: id, x: x} <- leds do
      hue = mod(trunc(x * steps) + time, 360)
      {id, HSV.new(hue, 100, 100)}
    end
  end

  defp render_colors(leds, steps, time, :up) do
    for %LED{id: id, y: y} <- leds do
      hue = mod(trunc(y * steps) + time, 360)
      {id, HSV.new(hue, 100, 100)}
    end
  end

  defp render_colors(leds, steps, time, :down) do
    for %LED{id: id, y: y} <- leds do
      hue = mod(trunc(y * steps) - time, 360)
      {id, HSV.new(hue, 100, 100)}
    end
  end
end
