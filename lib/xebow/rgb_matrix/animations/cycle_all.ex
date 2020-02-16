defmodule Xebow.RGBMatrix.Animations.CycleAll do
  @moduledoc """
  Cycles hue of all keys.
  """

  alias Chameleon.HSV
  alias Xebow.RGBMatrix
  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @impl true
  @spec tick(tick :: RGBMatrix.tick()) :: map
  def tick(tick) do
    speed = 100
    time = div(tick * speed, 100)

    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    %{color: color}
  end

  @impl true
  @spec color(
          x :: RGBMatrix.coordinate(),
          y :: RGBMatrix.coordinate(),
          tick :: RGBMatrix.tick(),
          tick_result :: map
        ) :: list(RGBMatrix.color())
  def color(_x, _y, _tick, %{color: color}) do
    color
  end
end
