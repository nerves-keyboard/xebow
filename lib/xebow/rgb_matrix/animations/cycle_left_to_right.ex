defmodule Xebow.RGBMatrix.Animations.CycleLeftToRight do
  @moduledoc """
  Cycles hue left to right.
  """

  alias Chameleon.HSV

  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @impl true
  def init_state do
    %{
      tick: 0,
      speed: 100,
      delay_ms: 17
    }
  end

  @impl true
  def next_state(pixels, state) do
    %{tick: tick, speed: speed} = state
    time = div(tick * speed, 100)

    colors =
      for {x, _y} <- pixels do
        hue = mod(x * 10 - time, 360)
        HSV.new(hue, 100, 100)
      end

    {colors, %{state | tick: tick + 1}}
  end
end
