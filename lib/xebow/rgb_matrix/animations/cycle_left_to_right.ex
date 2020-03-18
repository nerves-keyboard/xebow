defmodule Xebow.RGBMatrix.Animations.CycleLeftToRight do
  @moduledoc """
  Cycles hue left to right.
  """

  alias Chameleon.HSV

  # alias Xebow.RGBMatrix
  # alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @delay_ms 17

  # @behaviour Animation

  # @impl true
  def init do
    %{
      tick: 0,
      speed: 100
    }
  end

  # @impl true
  def run(pixels, state) do
    %{tick: tick, speed: speed} = state
    time = div(tick * speed, 100)

    colors =
      for {x, _y} <- pixels do
        hue = mod(x * 10 - time, 360)
        HSV.new(hue, 100, 100)
      end

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end
end
