defmodule Xebow.Animation.Loop do
  @moduledoc """
  Play a pre-defined animation on a loop.

  Note that the animation speed is controlled by the `:delay_ms` field of the `%Xebow.Animation` struct. The `:speed` field is not used at all for one shot animations.

  ## Examples
  ```
    gen_map = fn -> Enum.into(Xebow.Utils.pixels(), %{}, fn pixel -> {pixel, Chameleon.HSV.new(:random.uniform(360), 100, 100)} end) end
    generator = fn -> struct!(Xebow.AnimationFrame, pixel_map: gen_map.()) end

    frames = Stream.repeatedly(generator) |> Enum.take(10)

    animation =  
      %Xebow.Animation{
      delay_ms: 100,
      frames: frames,
      tick: 0,
      type: Xebow.Animation.Loop
    }

    Xebow.RGBMatrix.play_animation(animation)
  ```
  """

  alias Xebow.Animation

  import Xebow.Utils, only: [mod: 2]

  use Animation

  @impl Animation
  def next_frame(animation) do
    %Animation{frames: frames, tick: tick} = animation

    index = mod(tick, length(frames))

    Enum.at(frames, index)
  end
end
