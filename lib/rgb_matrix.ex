defmodule RGBMatrix do
  @moduledoc false

  @type any_color_model ::
          Chameleon.Color.RGB.t()
          | Chameleon.Color.CMYK.t()
          | Chameleon.Color.Hex.t()
          | Chameleon.Color.HSL.t()
          | Chameleon.Color.HSV.t()
          | Chameleon.Color.Keyword.t()
          | Chameleon.Color.Pantone.t()
end
