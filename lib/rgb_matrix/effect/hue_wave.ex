defmodule RGBMatrix.Effect.HueWave do
  @moduledoc """
  Creates a wave of shifting hue that moves across the matrix.
  """

  alias Chameleon.HSV
  alias Layout.LED
  alias RGBMatrix.Effect

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule Config do
    use RGBMatrix.Effect.Config

    @doc name: "Speed",
         description: """
         Controls the speed at which the wave moves across the matrix.
         """
    field(:speed, :integer, default: 4, min: 0, max: 32)

    @doc name: "Width",
         description: """
         The rate of change of the wave, higher values means it's more spread out.
         """
    field(:width, :integer, default: 20, min: 10, max: 100, step: 10)

    @doc name: "Direction",
         description: """
         The direction the wave travels across the matrix.
         """
    field(:direction, :option,
      default: :right,
      options: [
        :right,
        :left,
        :up,
        :down
      ]
    )
  end

  defmodule State do
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

    # TODO: fixme
    steps = 360 / config.width

    time = div(tick * speed, 5)

    colors = render_colors(leds, steps, time, direction)

    {colors, @delay_ms, %{state | tick: tick + 1}}
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

  @impl true
  def interact(state, _config, _led) do
    {:ignore, state}
  end
end
