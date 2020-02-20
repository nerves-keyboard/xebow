defmodule Xebow.RGBMatrix.Animations.Pinwheel do
  @moduledoc """
  Cycles hue in a pinwheel pattern.
  """

  alias Chameleon.HSV
  alias Xebow.RGBMatrix
  alias Xebow.RGBMatrix.Animation

  import Xebow.Utils, only: [mod: 2]

  @behaviour Animation

  @center %{
    x: 1,
    y: 1.5
  }

  @impl true
  @spec tick(tick :: RGBMatrix.tick()) :: nil
  def tick(tick) do
    speed = 100
    time = div(tick * speed, 100)

    %{time: time}
  end

  @impl true
  @spec color(
          x :: RGBMatrix.coordinate(),
          y :: RGBMatrix.coordinate(),
          tick :: RGBMatrix.tick(),
          tick_result :: map
        ) :: list(RGBMatrix.color())
  def color(x, y, _tick, %{time: time}) do
    dx = x - @center.x
    dy = y - @center.y

    hue = mod(atan2_8(dy, dx) + time, 360)

    HSV.new(hue, 100, 100)
  end

  defp atan2_8(x, y) do
    atan = :math.atan2(x, y)

    trunc((atan + :math.pi()) * 359 / (2 * :math.pi()))
  end
end
