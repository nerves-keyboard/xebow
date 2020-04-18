defmodule Xebow.RGBMatrix.Animations.Pinwheel do
  @moduledoc """
  Cycles hue in a pinwheel pattern.
  """

  alias Chameleon.HSV

  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @center %{
    x: 1,
    y: 1.5
  }

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
      for {x, y} <- pixels do
        dx = x - @center.x
        dy = y - @center.y

        hue = mod(atan2_8(dy, dx) + time, 360)

        HSV.new(hue, 100, 100)
      end

    %Animation{animation | pixel_colors: pixel_colors}
    |> Animation.do_tick()
  end

  defp atan2_8(x, y) do
    atan = :math.atan2(x, y)

    trunc((atan + :math.pi()) * 359 / (2 * :math.pi()))
  end
end
