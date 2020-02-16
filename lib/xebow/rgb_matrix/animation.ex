defmodule Xebow.RGBMatrix.Animation do
  alias Xebow.RGBMatrix

  @callback tick(tick :: RGBMatrix.tick()) :: any
  @callback color(
              x :: RGBMatrix.coordinate(),
              y :: RGBMatrix.coordinate(),
              tick :: RGBMatrix.tick(),
              tick_result :: any
            ) :: list(RGBMatrix.color())
end
