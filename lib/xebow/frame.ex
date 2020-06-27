defmodule Xebow.Frame do
  @moduledoc """
  Provides a data structure and functions for working with animation frames.

  An animation frame is a mapping of pixel coordinates to their corresponding color. An animation can be composed of a
  list of frames or each frame can be dynamically generated based on the tick of some animation.
  """

  alias Xebow.Pixel

  @type pixel_map :: %{required(Pixel.t()) => Pixel.color()}

  @type t :: %__MODULE__{
          pixel_map: pixel_map()
        }

  defstruct [:pixel_map]

  @spec new(pixels :: list(Pixel.t()), pixel_colors :: list(Pixel.color())) ::
          t()
  def new(pixels, pixel_colors) do
    pixel_map =
      Enum.zip(pixels, pixel_colors)
      |> Enum.into(%{})

    %__MODULE__{pixel_map: pixel_map}
  end

  @spec solid_color(pixels :: list(Pixel.t()), color :: Pixel.color()) :: t()
  def solid_color(pixels, color) do
    pixel_colors = List.duplicate(color, length(pixels))
    new(pixels, pixel_colors)
  end
end
