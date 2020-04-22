defmodule Xebow.Animation.CycleAll do
  @moduledoc """
  Cycles hue of all keys.
  """

  alias Chameleon.HSV

  alias Xebow.Animation

  import Xebow.Utils, only: [mod: 2]

  use Animation

  @impl true
  def next_state(animation) do
    %Animation{tick: tick, speed: speed, pixels: pixels} = animation
    time = div(tick * speed, 100)

    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    pixel_colors = Enum.map(pixels, fn {_x, _y} -> color end)

    %Animation{animation | pixel_colors: pixel_colors}
    |> do_tick()
  end
end
