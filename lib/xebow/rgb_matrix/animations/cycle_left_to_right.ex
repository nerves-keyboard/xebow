defmodule Xebow.RGBMatrix.Animations.CycleLeftToRight do
  @moduledoc """
  Cycles hue left to right.
  """

  alias Chameleon.HSV
  alias Xebow.RGBMatrix
  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @impl true
  @spec run(
          x :: RGBMatrix.coordinate(),
          y :: RGBMatrix.coordinate(),
          tick :: RGBMatrix.tick()
        ) :: list(RGBMatrix.color())
  def run(x, _y, tick) do
    hue = mod(tick - x * 10, 360)
    HSV.new(hue, 100, 100)
  end
end
