defmodule Xebow.RGBMatrix.Animation do
  alias Xebow.RGBMatrix

  @callback init_state(pixels :: list(RGBMatrix.pixel())) :: map
  @callback next_state(
              pixels :: list(RGBMatrix.pixel()),
              state :: map
            ) :: map

  @doc """
  Increment the animation state to the next tick.
  This function is intended to be used by implementations of an `Animation`.
  """
  def do_tick(animation_state) do
    %{animation_state | tick: animation_state.tick + 1}
  end

  @doc """
  Initialize a list of default pixel colors.
  The default sets all pixels to be turned off ("black").
  """
  @spec init_pixel_colors(pixels :: list(RGBMatrix.pixel())) :: list(RGBMatrix.pixel_color())
  def init_pixel_colors(pixels) do
    Enum.map(pixels, fn _pixel -> Chameleon.HSV.new(0, 0, 0) end)
  end
end
