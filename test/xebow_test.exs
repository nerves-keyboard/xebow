defmodule XebowTest do
  use ExUnit.Case

  test "holds the xebow layout" do
    assert %Layout{} = Xebow.layout()
  end
end
