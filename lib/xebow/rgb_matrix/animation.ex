defmodule Xebow.RGBMatrix.Animation do
  alias Xebow.RGBMatrix

  @callback init_state :: any
  @callback next_state(
              pixels :: RGBMatrix.pixels(),
              state :: any
            ) :: {RGBMatrix.colors(), any}
end
