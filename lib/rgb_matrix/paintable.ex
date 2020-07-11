defmodule RGBMatrix.Paintable do
  @moduledoc """
  A paintable module controls physical LEDs.
  """

  alias Layout.LED

  @type frame :: %{required(LED.id()) => RGBMatrix.any_color_model()}

  @doc """
  Returns a function that can be called to paint the LEDs for a given frame. The
  anonymous function's return value is unused.

  This callback makes any hardware implementation details opaque to the caller,
  while allowing the paintable to retain control of the physical LEDs.
  """
  @callback get_paint_fn :: (frame -> any)
end
