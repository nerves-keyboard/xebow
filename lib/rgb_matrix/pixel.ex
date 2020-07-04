defmodule RGBMatrix.Pixel do
  @moduledoc """
  A pixel is a unit that has X and Y coordinates and displays a single color.
  """

  @typedoc """
  A tuple containing the X and Y coordinates of the pixel.
  """
  @type t :: {x :: non_neg_integer, y :: non_neg_integer}

  @typedoc """
  The color of the pixel, represented as a `Chameleon.Color` color model.
  """
  @type color :: any_color_model

  @typedoc """
  Shorthand for any `Chameleon.Color` color model.
  """
  @type any_color_model ::
          Chameleon.Color.RGB.t()
          | Chameleon.Color.CMYK.t()
          | Chameleon.Color.Hex.t()
          | Chameleon.Color.HSL.t()
          | Chameleon.Color.HSV.t()
          | Chameleon.Color.Keyword.t()
          | Chameleon.Color.Pantone.t()
end
