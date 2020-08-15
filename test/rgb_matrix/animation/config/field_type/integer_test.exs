defmodule IntegerTest do
  use ExUnit.Case

  alias RGBMatrix.Animation.Config.FieldType.Integer

  defp test_integer(_context) do
    [
      test_integer: %Integer{
        default: 5,
        min: 1,
        max: 11,
        step: 2
      }
    ]
  end

  describe "Integer field type function `validate/2`" do
    setup :test_integer

    test "receives valid integer input and returns `:ok`", context do
      assert Integer.validate(context.test_integer, 3) == :ok
    end

    test "receives invalid step-multiple input and returns `:validation_error`", context do
      assert Integer.validate(context.test_integer, 4) == :validation_error
    end

    test "receives invalid out-of-range input and returns `:validation_error`", context do
      assert Integer.validate(context.test_integer, 13) == :validation_error
    end
  end

  describe "Integer field type function `cast/2`" do
    setup :test_integer

    test "receives valid string input and returns `{:ok, <value>}`", context do
      assert Integer.cast(context.test_integer, "7") == {:ok, 7}
    end

    test "receives valid integer input and returns `{:ok, <value}`", context do
      assert Integer.cast(context.test_integer, 7) == {:ok, 7}
    end

    test "receives float string input and returns the integer part only", context do
      assert Integer.cast(context.test_integer, "1.0") == {:ok, 1}
    end

    test "receives float input and returns the integer part only", context do
      assert Integer.cast(context.test_integer, 9.0) == {:ok, 9}
    end

    test "receives invalid input and returns `:cast_error`", context do
      assert Integer.cast(context.test_integer, "fish") == :cast_error
      assert Integer.cast(context.test_integer, %{value: 4}) == :cast_error
    end

    test "receives integer string input that is invalid for the field definition and returns `:validation_error`",
         context do
      assert Integer.cast(context.test_integer, "4") == :validation_error
    end

    test "receives integer input that is invalid for the field definition and returns `:validation_error`",
         context do
      assert Integer.cast(context.test_integer, 6) == :validation_error
    end
  end
end
