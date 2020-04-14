defmodule Xebow.RGBMatrix.Animations.CycleAll do
  @moduledoc """
  Cycles hue of all keys.
  """

  alias Chameleon.HSV

  # alias Xebow.RGBMatrix
  # alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @delay_ms 17

  # @behaviour Animation

  # @impl true
  def init do
    %{
      tick: 0,
      speed: 100
    }
  end

  # @impl true
  def run(pixels, state) do
    %{tick: tick, speed: speed} = state
    time = div(tick * speed, 100)

    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

colors = Enum.map(pixels, fn {_x, _y} -> color end)

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end
end
