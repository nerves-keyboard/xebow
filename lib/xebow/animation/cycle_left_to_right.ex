defmodule Xebow.Animation.CycleLeftToRight do
  @moduledoc """
  Cycles hue left to right.
  """

  alias Chameleon.HSV

  alias Xebow.Animation

  import Xebow.Utils, only: [mod: 2]

  use Animation

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
    |> do_tick()
  end
end
