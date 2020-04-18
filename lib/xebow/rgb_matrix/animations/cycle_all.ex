defmodule Xebow.RGBMatrix.Animations.CycleAll do
  @moduledoc """
  Cycles hue of all keys.
  """

  alias Chameleon.HSV

  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @impl true
  def init_state(pixels) do
    %{
      tick: 0,
      speed: 100,
      delay_ms: 17,
      pixel_colors: Animation.init_pixel_colors(pixels)
    }
  end

  @impl true
  def next_state(pixels, state) do
    %{tick: tick, speed: speed} = state
    time = div(tick * speed, 100)

    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    pixel_colors = Enum.map(pixels, fn {_x, _y} -> color end)

    %{state | pixel_colors: pixel_colors}
    |> Animation.do_tick()
  end
end
