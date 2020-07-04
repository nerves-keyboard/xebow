defmodule RGBMatrix.Animation.CycleAll do
  @moduledoc """
  Cycles hue of all keys.
  """

  alias Chameleon.HSV

  alias RGBMatrix.{Animation, Frame}

  import RGBMatrix.Utils, only: [mod: 2]

  use Animation

  @impl Animation
  def next_frame(animation) do
    %Animation{tick: tick, speed: speed} = animation
    time = div(tick * speed, 100)

    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    # FIXME: no reaching into Xebow namespace
    pixels = Xebow.Utils.pixels()
    pixel_colors = Enum.map(pixels, fn {_x, _y} -> color end)

    Frame.new(pixels, pixel_colors)
  end
end
