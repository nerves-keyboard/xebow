defmodule Xebow.AnimationFrame do
  @moduledoc false

  alias Xebow.RGBMatrix

  @type pixel_map :: %{required(RGBMatrix.pixel()) => RGBMatrix.pixel_color()}

  @type t :: %__MODULE__{
          pixel_map: pixel_map()
        }

  defstruct [:pixel_map]

  @spec new(pixels :: list(RGBMatrix.pixel()), pixel_colors :: list(RGBMatrix.pixel_color())) ::
          t()
  def new(pixels, pixel_colors) do
    pixel_map =
      Enum.zip(pixels, pixel_colors)
      |> Enum.into(%{})

    %__MODULE__{pixel_map: pixel_map}
  end

  @spec solid_color(pixels :: list(RGBMatrix.pixel()), color :: RGBMatrix.pixel_color()) :: t()
  def solid_color(pixels, color) do
    pixel_colors = List.duplicate(color, length(pixels))
    new(pixels, pixel_colors)
  end
end
