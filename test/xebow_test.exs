defmodule XebowTest do
  use ExUnit.Case

  alias RGBMatrix.Animation

  defmodule MockAnimations.Type1 do
    use Animation

    @impl Animation
    def new(_leds, _config) do
      nil
    end

    @impl Animation
    def render(_state, _config) do
      {1000, [], nil}
    end
  end

  test "has a layout for the keybow" do
    assert %Layout{} = Xebow.layout(:keybow)
  end

  test "has a layout for excalibur" do
    assert %Layout{} = Xebow.layout(:excalibur)
  end

  test "can get and set active animation types" do
    animation_types = [MockAnimations.Type1]

    assert Xebow.get_active_animation_types() != animation_types

    Xebow.set_active_animation_types(animation_types)

    assert Xebow.get_active_animation_types() == animation_types
  end
end
