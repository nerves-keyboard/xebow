defmodule Xebow.RGBMatrix.Animation do
  alias Xebow.RGBMatrix

  @callback init_state(pixels :: list(RGBMatrix.pixel())) :: t
  @callback next_state(
              pixels :: list(RGBMatrix.pixel()),
              animation :: t
            ) :: t

  @type t :: %__MODULE__{
          tick: non_neg_integer,
          speed: non_neg_integer,
          delay_ms: non_neg_integer,
          pixel_colors: list(RGBMatrix.pixel_color())
        }
  defstruct [:tick, :speed, :delay_ms, :pixel_colors]

  @doc """
  Increment the animation state to the next tick.
  This function is intended to be used by implementations of an `Animation`.
  """
  @spec do_tick(animation :: t) :: t
  def do_tick(animation) do
    %__MODULE__{animation | tick: animation.tick + 1}
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
