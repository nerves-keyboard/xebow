defmodule RGBMatrix.Paintable do
  @moduledoc """
  A paintable module controls physical pixels.
  """

  @doc """
  Returns a function that can be called to paint the pixels for a given frame.
  The anonymous function's return value is unused.

  This callback makes any hardware implementation details opaque to the caller,
  while allowing the paintable to retain control of the physical pixels.
  """
  @callback get_paint_fn :: (frame :: RGBMatrix.Frame.t() -> any)
end
