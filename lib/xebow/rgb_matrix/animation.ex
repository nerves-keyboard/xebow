defmodule Xebow.RGBMatrix.Animation do
  alias Xebow.RGBMatrix

  @callback run(
              x :: RGBMatrix.coordinate(),
              y :: RGBMatrix.coordinate(),
              tick :: RGBMatrix.tick()
            ) :: list(RGBMatrix.color())
end
