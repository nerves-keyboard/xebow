defmodule Xebow.RGBMatrix.Animation do
  alias Xebow.RGBMatrix

  @callback init_state :: any
  @callback next_state(
              pixels :: RGBMatrix.pixels(),
              state :: any
            ) :: {RGBMatrix.colors(), any}

  @doc """
  Increment the animation state to the next tick.
  This function is intended to be used by implementations of an `Animation`.
  """
  def do_tick(animation_state) do
    %{animation_state | tick: animation_state.tick + 1}
  end
end
