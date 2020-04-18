defmodule Xebow.RGBMatrix.Animations.CycleAll do
  @moduledoc """
  Cycles hue of all keys.
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

    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    colors = Enum.map(pixels, fn {_x, _y} -> color end)

    animation_next_state = Animation.do_tick(state)

    {colors, animation_next_state}
  end
end
