defmodule Xebow.Animation.OneShot do
  @moduledoc """
  Play a pre-defined animation once.

  Note that the animation speed is controlled by the `:delay_ms` field of the `%Xebow.Animation` struct. The `:speed` field is not used at all for one shot animations.

  ## Examples
  ```
  frames = [
    %Xebow.AnimationFrame{
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
    %Xebow.AnimationFrame{
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

  animation = %Xebow.Animation{
    frames: frames,
    delay_ms: 200,
    tick: 0,
    type: Xebow.Animation.OneShot
  }

  Xebow.RGBMatrix.play_one_shot(animation)
  ```
  """

  alias Xebow.Animation

  use Animation

  @impl Animation
  def next_frame(animation) do
    %Animation{frames: frames, tick: tick} = animation
    Enum.at(frames, tick)
  end
end
