defmodule XebowTest do
  use ExUnit.Case

  describe "Xebow Application" do
    test "has layout" do
      assert %Layout{} = Xebow.layout()
    end
  end
end
