defmodule RGBMatrix.Effect.Pinwheel do
  @moduledoc """
  Cycles hue in a pinwheel pattern.
  """

  alias Chameleon.HSV
  alias Layout.LED
  alias RGBMatrix.Effect

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule Config do
    use RGBMatrix.Effect.Config
  end

  defmodule State do
    defstruct [:tick, :speed, :leds, :center]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    {0, %State{tick: 0, speed: 100, leds: leds, center: determine_center(leds)}}
  end

  defp determine_center(leds) do
    {%{x: min_x}, %{x: max_x}} = Enum.min_max_by(leds, & &1.x)
    {%{y: min_y}, %{y: max_y}} = Enum.min_max_by(leds, & &1.y)

    %{
      x: (max_x - min_x) / 2 + min_x,
      y: (max_y - min_y) / 2 + min_y
    }
  end

  @impl true
  def render(state, _config) do
    %{tick: tick, speed: speed, leds: leds, center: center} = state

    time = div(tick * speed, 100)

    colors =
      for %LED{id: id, x: x, y: y} <- leds do
        dx = x - center.x
        dy = y - center.y

        hue = mod(atan2_8(dy, dx) + time, 360)

        {id, HSV.new(hue, 100, 100)}
      end

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end

  defp atan2_8(x, y) do
    atan = :math.atan2(x, y)

    trunc((atan + :math.pi()) * 359 / (2 * :math.pi()))
  end

  @impl true
  def interact(state, _config, %LED{x: x, y: y}) do
    {:ignore, %{state | center: %{x: x, y: y}}}
  end
end
