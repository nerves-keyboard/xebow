defmodule RGBMatrix.Animation.CycleLeftToRight do
  @moduledoc """
  Cycles hue left to right.
  """

  alias Chameleon.HSV

  alias RGBMatrix.{Animation, Frame}

  import RGBMatrix.Utils, only: [mod: 2]

  use Animation

  @impl Animation
  def next_frame(animation) do
    %Animation{tick: tick, speed: speed} = animation
    time = div(tick * speed, 100)

    # FIXME: no reaching into Xebow namespace
    pixels = Xebow.Utils.pixels()

    pixel_colors =
      for {x, _y} <- pixels do
        hue = mod(x * 10 - time, 360)
        HSV.new(hue, 100, 100)
      end

    Frame.new(pixels, pixel_colors)
  end
end
