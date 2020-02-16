defmodule Xebow.RGBMatrix.Animations do
  alias Xebow.RGBMatrix.Animations

  def animations do
    [
      Animations.CycleAll,
      Animations.CycleLeftToRight,
      Animations.Pinwheel
    ]
  end
end
