defmodule RGBMatrix.Animation.Static do
  @moduledoc """
  Pre-defined animations that run as a one-shot or on a loop.

  The `RGBMatrix.Animation.Static` animation type is used to define animations with a pre-defined set of frames. These
  animations can be played continiously or on a loop. This behavior is controlled by the `:loop` field on the animation.
  A value of `:infinite` means to play the animation continuously, while a value greater than 0 means to loop the animation
  `:loop` times.

  Note that the playback speed of these animations is controlled by the `:delay_ms` field in the animation struct. The
  `:speed` field not used when rendering these animations.

  ## Examples

  ### Play a random color on each pixel for 10 frames, continuously.
  ```
  gen_map = fn ->
    Enum.into(Xebow.Utils.pixels(), %{}, fn pixel ->
      {pixel, Chameleon.HSV.new(:random.uniform(360), 100, 100)}
    end)
  end

  generator = fn -> struct!(RGBMatrix.Frame, pixel_map: gen_map.()) end
  frames = Stream.repeatedly(generator) |> Enum.take(10)

  animation =
    %RGBMatrix.Animation{
    delay_ms: 100,
    frames: frames,
    tick: 0,
    loop: :infinite,
    type: RGBMatrix.Animation.Static
  }

  Xebow.LEDs.play_animation(animation)
  ```

  ### Play a pre-defined animation, three times
  ```
  frames = [
    %RGBMatrix.Frame{
      pixel_map: %{
        {0, 0} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {0, 1} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {0, 2} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {0, 3} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {1, 0} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {1, 1} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {1, 2} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {1, 3} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {2, 0} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {2, 1} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {2, 2} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {2, 3} => %Chameleon.HSV{h: 100, s: 100, v: 100}
      }
    },
    %RGBMatrix.Frame{
      pixel_map: %{
        {0, 0} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {0, 1} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {0, 2} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {0, 3} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {1, 0} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {1, 1} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {1, 2} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {1, 3} => %Chameleon.HSV{h: 100, s: 100, v: 100},
        {2, 0} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {2, 1} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {2, 2} => %Chameleon.HSV{h: 0, s: 0, v: 0},
        {2, 3} => %Chameleon.HSV{h: 0, s: 0, v: 0}
      }
    }
  ]

  animation = %RGBMatrix.Animation{
    delay_ms: 200,
    frames: frames,
    tick: 0,
    loop: 3,
    type: RGBMatrix.Animation.Static
  }

  Xebow.LEDs.play_animation(animation)
  ```
  """

  alias RGBMatrix.Animation

  import RGBMatrix.Utils, only: [mod: 2]

  use Animation

  @impl Animation
  def next_frame(%{loop: :infinite} = animation) do
    %Animation{frames: frames, tick: tick} = animation

    index = mod(tick, length(frames))
    Enum.at(frames, index)
  end

  @impl Animation
  def next_frame(animation) do
    %Animation{frames: frames, tick: tick, loop: loop} = animation

    all_frames = all_frames(frames, loop)
    index = mod(tick, length(all_frames))
    Enum.at(all_frames, index)
  end

  defp all_frames(frames, loop) do
    List.duplicate(frames, loop)
    |> List.flatten()
  end
end
