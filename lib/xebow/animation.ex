defmodule Xebow.Animation do
  @moduledoc """
  Provides a data structure and functions to define a Xebow animation.

  There are currently two distinct ways to define an animation.

  You may define an animation with a predefined `:frames` field. Each frame will advance every `:delay_ms` milliseconds. These animations should use the `Xebow.Animation.Loop` `:type`. See the moduledoc of `Xebow.Animation.Loop` for an example. These animations should have a nil `:frame_buffer_length`.

  Alternatively, you may have a more dynamic animation which generates frames based on the current `:tick` of the animation. See `Xebow.Animation.{CycleAll, CycleLeftToRight, Pinwheel} for examples.

  For the dynamic animations, the last `:frame_buffer_length` frames of animation are stored in the `:frames` field of the `%Xebow.Animation{}` struct. These are not currently being used, however, they can be used for animations that depend on events around the LED matrix. For example, a "wave" effect that reflects off of the matrix edges / key presses.
  """

  alias Xebow.{AnimationFrame, RGBMatrix}

  @callback init_state(frames :: list(AnimationFrame.t())) :: t
  @callback next_frame(animation :: t) :: AnimationFrame.t()
  @callback next_state(animation :: t) :: t

  @type t :: %__MODULE__{
          type: type,
          tick: non_neg_integer,
          speed: non_neg_integer,
          delay_ms: non_neg_integer,
          frames: list(AnimationFrame.t()),
          next_frame: AnimationFrame.t() | nil,
          frame_buffer_length: pos_integer | nil
        }
  defstruct [:type, :tick, :speed, :delay_ms, :next_frame, :frames, :frame_buffer_length]

  # Helpers for implementing animations.
  defmacro __using__(_) do
    quote do
      alias Xebow.Animation

      @behaviour Animation

      @impl Animation
      def init_state(pixels) do
        init_state_from_defaults(__MODULE__, pixels)
      end

      @impl Animation
      @spec next_state(animation :: Animation.t()) :: Animation.t()
      # Predefined animations
      def next_state(%{frame_buffer_length: nil} = animation) do
        next_frame = next_frame(animation)

        %Animation{animation | next_frame: next_frame, tick: animation.tick + 1}
      end

      # Dynamic animations
      def next_state(animation) do
        next_frame = next_frame(animation)
        frames = [next_frame | animation.frames]
        frames = buffer_frames(frames, animation.frame_buffer_length)

        %Animation{animation | next_frame: next_frame, frames: frames, tick: animation.tick + 1}
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
          next_frame: nil,
          frames: [init_frame],
          frame_buffer_length: opts[:frame_buffer_length] || 3
        }
      end

      # Initialize a list of default pixel colors.
      # The default sets all pixels to be turned off ("black").
      @spec init_pixel_colors(pixels :: list(RGBMatrix.pixel())) :: list(RGBMatrix.pixel_color())
      defp init_pixel_colors(pixels) do
        Enum.map(pixels, fn _pixel -> Chameleon.HSV.new(0, 0, 0) end)
      end

      # We don't want the length of the frame buffer to continuously grow, however, we do
      # want to store some of the frames so animations can use previous frames as reference.
      defp buffer_frames(frames, buffer_len), do: Enum.take(frames, buffer_len)

      defoverridable init_state: 1
    end
  end

  @type type ::
          __MODULE__.CycleAll
          | __MODULE__.CycleLeftToRight
          | __MODULE__.Pinwheel
          | __MODULE__.Loop
          | __MODULE__.OneShot

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
  Returns the next frame of an animation based on its current state.
  """
  @spec next_frame(animation :: t) :: AnimationFrame.t()
  def next_frame(animation) do
    animation.type.next_frame(animation)
  end

  def next_state(animation) do
    animation.type.next_state(animation)
  end
end
