defmodule LayoutLEDTest do
  use ExUnit.Case

  alias Layout.LED

  test "new/3 takes 3 arguments and creates a %Layout.LED{} struct" do
    assert LED.new(:l1, 0, 0) == %LED{id: :l1, x: 0, y: 0}
    assert LED.new(:l2, 1, 3) == %LED{id: :l2, x: 1, y: 3}
  end
end
