defmodule Xebow.RGBMatrix.Animations.CycleLeftToRight do
  @moduledoc """
  Cycles hue left to right.
  """

  alias Chameleon.HSV

  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @impl true
  def init_state(pixels) do
    %Animation{
      tick: 0,
      speed: 100,
      delay_ms: 17,
      pixels: pixels,
      pixel_colors: Animation.init_pixel_colors(pixels)
    }
  end

  @impl true
  def next_state(animation) do
    %Animation{tick: tick, speed: speed, pixels: pixels} = animation
    time = div(tick * speed, 100)

    pixel_colors =
      for {x, _y} <- pixels do
        hue = mod(x * 10 - time, 360)
        HSV.new(hue, 100, 100)
      end

    %Animation{animation | pixel_colors: pixel_colors}
    |> Animation.do_tick()
  end
end
