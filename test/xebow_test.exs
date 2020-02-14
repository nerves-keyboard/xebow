defmodule XebowTest do
  use ExUnit.Case
  doctest Xebow

  test "greets the world" do
    assert Xebow.hello() == :world
  end
end
