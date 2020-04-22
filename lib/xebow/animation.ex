defmodule Xebow.Animation do
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

  # Helpers for implementing animations.
  defmacro __using__(_) do
    quote do
      alias Xebow.Animation

      @behaviour Animation

      @impl true
      def init_state(pixels) do
        init_state_from_defaults(__MODULE__, pixels)
      end

      # Increment the animation state to the next tick.
      @spec do_tick(animation :: Animation.t()) :: Animation.t()
      defp do_tick(animation) do
        %Animation{animation | tick: animation.tick + 1}
      end

      # Initialize an `Animation` struct with default values.
      # Defaults can be overridden by passing the corresponding keyword as `opts`.
      @spec init_state_from_defaults(
              animation_type :: Animation.type(),
              pixels :: list(RGBMatrix.pixel()),
              opts :: list(keyword)
            ) :: Animation.t()
      defp init_state_from_defaults(animation_type, pixels, opts \\ []) do
        %Animation{
          type: animation_type,
          tick: opts[:tick] || 0,
          speed: opts[:speed] || 100,
          delay_ms: opts[:delay_ms] || 17,
          pixels: pixels,
          pixel_colors: opts[:pixel_colors] || init_pixel_colors(pixels)
        }
      end

      # Initialize a list of default pixel colors.
      # The default sets all pixels to be turned off ("black").
      @spec init_pixel_colors(pixels :: list(RGBMatrix.pixel())) :: list(RGBMatrix.pixel_color())
      defp init_pixel_colors(pixels) do
        Enum.map(pixels, fn _pixel -> Chameleon.HSV.new(0, 0, 0) end)
      end

      defoverridable init_state: 1
    end
  end

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
end
