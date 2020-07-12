defmodule XebowTest do
  use ExUnit.Case

  test "has layout" do
    assert %Layout{} = Xebow.layout()
  end
end
