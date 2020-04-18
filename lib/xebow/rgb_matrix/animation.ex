defmodule Xebow.RGBMatrix.Animation do
  alias Xebow.RGBMatrix

  @callback init_state(pixels :: list(RGBMatrix.pixel())) :: t
  @callback next_state(animation :: t) :: t

  @type t :: %__MODULE__{
          type: type,
          tick: non_neg_integer,
          speed: non_neg_integer,
          delay_ms: non_neg_integer,
          pixels: list(RGBMatrix.pixel()),
          pixel_colors: list(RGBMatrix.pixel_color())
        }
  defstruct [:type, :tick, :speed, :delay_ms, :pixels, :pixel_colors]

  @type type ::
          __MODULE__.CycleAll
          | __MODULE__.CycleLeftToRight
          | __MODULE__.Pinwheel

  @doc """
  Returns a list of the available types of animations.
  """
  @spec types :: list(type)
  def types do
    [
      __MODULE__.CycleAll,
      __MODULE__.CycleLeftToRight,
      __MODULE__.Pinwheel
    ]
  end

  @doc """
  Returns an animation set to its initial state.
  """
  @spec init_state(animation_type :: type, pixels :: list(RGBMatrix.pixel())) :: t
  def init_state(animation_type, pixels) do
    animation_type.init_state(pixels)
  end

  @doc """
  Returns the next state of an animation based on its current state.
  """
  @spec next_state(animation :: t) :: t
  def next_state(animation) do
    animation.type.next_state(animation)
  end

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
