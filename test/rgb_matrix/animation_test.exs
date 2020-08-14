defmodule RGBMatrix.AnimationTest do
  use ExUnit.Case

  alias RGBMatrix.Animation

  test "can get an animation type's human-readable name" do
    defmodule MockAnimation.HueWave do
    end

    assert Animation.type_name(MockAnimation.HueWave) == "Hue Wave"
  end
end
