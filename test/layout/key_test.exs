defmodule LayoutKeyTest do
  use ExUnit.Case

  alias Layout.Key

  test "new/3 creates a %Key{} struct with default :width, :height, and :led" do
    assert Key.new(:a, 0, 0) == %Key{id: :a, x: 0, y: 0, width: 1, height: 1, led: nil}
    assert Key.new(:b, 1, 2) == %Key{id: :b, x: 1, y: 2, width: 1, height: 1, led: nil}
  end

  test "new/4 allows setting :width, :height, and :led" do
    assert Key.new(:a, 1, 2, width: 3, height: 4, led: :b) ==
             %Key{id: :a, x: 1, y: 2, width: 3, height: 4, led: :b}
  end

  test "new/4 allows setting :led only" do
    assert Key.new(:b, 2, 4, led: :c) ==
             %Key{id: :b, x: 2, y: 4, led: :c, width: 1, height: 1}
  end

  test "new/4 allows setting :width or :height only" do
    assert Key.new(:l001, 1, 1, width: 1.5) ==
             %Key{id: :l001, x: 1, y: 1, width: 1.5, height: 1, led: nil}
    assert Key.new(:l002, 2, 3, height: 2) ==
             %Key{id: :l002, x: 2, y: 3, width: 1, height: 2, led: nil}
  end
end
