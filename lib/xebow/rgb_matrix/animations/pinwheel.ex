defmodule Xebow.RGBMatrix.Animations.Pinwheel do
  @moduledoc """
  Cycles hue in a pinwheel pattern.
  """

  alias Chameleon.HSV

  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @delay_ms 17

  @impl true
  def init_state do
    %{
      tick: 0,
      speed: 100,
      center: %{
        x: 1,
        y: 1.5
      }
    }
  end

  @impl true
  def next_state(pixels, state) do
    %{tick: tick, speed: speed} = state
    time = div(tick * speed, 100)

    colors =
      for {x, y} <- pixels do
        dx = x - state.center.x
        dy = y - state.center.y

        hue = mod(atan2_8(dy, dx) + time, 360)

        HSV.new(hue, 100, 100)
      end

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end

  defp atan2_8(x, y) do
    atan = :math.atan2(x, y)

    trunc((atan + :math.pi()) * 359 / (2 * :math.pi()))
  end
end
