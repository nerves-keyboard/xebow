defmodule Xebow.Animation do
  @moduledoc """
  Provides a data structure and functions to define a Xebow animation.

  There are currently two distinct ways to define an animation.

  You may define an animation with a predefined `:frames` field. Each frame will advance every `:delay_ms` milliseconds.
  These animations should use the `Xebow.Animation.{OneShot,Loop}` `:type`. See the moduledocs of those modules for
  examples.

  Alternatively, you may have a more dynamic animation which generates frames based on the current `:tick` of the
  animation. See `Xebow.Animation.{CycleAll, CycleLeftToRight, Pinwheel} for examples.
  """

  alias __MODULE__
  alias Xebow.{AnimationFrame, RGBMatrix}

  @callback init_state(frames :: list(AnimationFrame.t())) :: t
  @callback next_frame(animation :: Animation.t()) :: AnimationFrame.t()

  @type t :: %__MODULE__{
          type: type,
          tick: non_neg_integer,
          speed: non_neg_integer,
          loop: non_neg_integer | -1,
          delay_ms: non_neg_integer,
          frames: list(AnimationFrame.t()),
          next_frame: AnimationFrame.t()
        }
  defstruct [:type, :tick, :speed, :delay_ms, :loop, :next_frame, :frames]

  # Helpers for implementing animations.
  defmacro __using__(_) do
    quote do
      alias Xebow.Animation

      @behaviour Animation

      @impl Animation
      def init_state(pixels) do
        init_state_from_defaults(__MODULE__, pixels)
      end

      # Initialize an `Animation` struct with default values.
      # Defaults can be overridden by passing the corresponding keyword as `opts`.
      @spec init_state_from_defaults(
              animation_type :: Animation.type(),
              pixels :: list(RGBMatrix.pixel()),
              opts :: list(keyword)
            ) :: Animation.t()
      defp init_state_from_defaults(animation_type, pixels, opts \\ []) do
        init_frame = AnimationFrame.new(pixels, opts[:pixel_colors] || init_pixel_colors(pixels))

        %Animation{
          type: animation_type,
          tick: opts[:tick] || 0,
          speed: opts[:speed] || 100,
          delay_ms: opts[:delay_ms] || 17,
          loop: opts[:loop] || -1,
          next_frame: init_frame,
          frames: [init_frame]
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
          | __MODULE__.Static

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
  Updates the state of an animation with the next tick of animation.
  """
  @spec next_frame(animation :: Animation.t()) :: Animation.t()
  def next_frame(animation) do
    next_frame = animation.type.next_frame(animation)
    %Animation{animation | next_frame: next_frame, tick: animation.tick + 1}
  end

  @doc """
  Returns the frame count of a given animation,

  Note: this function returns -1 for dynamic animations.
  """
  @spec frame_count(animation :: Animation.t()) :: non_neg_integer | -1
  def frame_count(%{loop: -1}), do: -1

  def frame_count(animation), do: length(animation.frames) * animation.loop

  @doc """
  Returns the expected duration of a given animation.

  Note: this function returns -1 for dynamic animations.
  """
  @spec duration(animation :: Animation.t()) :: non_neg_integer | -1
  def duration(%{loop: -1}), do: -1

  def duration(animation), do: frame_count(animation) * animation.delay_ms
end
