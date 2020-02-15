defmodule Xebow.RGBMatrix.Animations.CycleAll do
  @moduledoc """
  Cycles hue of all keys.
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
  def run(_x, _y, tick) do
    hue = mod(tick, 360)
    HSV.new(hue, 100, 100)
  end
end
