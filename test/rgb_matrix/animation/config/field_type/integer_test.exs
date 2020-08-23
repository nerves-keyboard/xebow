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

    test "receives invalid step-multiple input and returns `{:error, :invalid_value}`", context do
      assert Integer.validate(context.test_integer, 4) == {:error, :invalid_value}
    end

    test "receives invalid out-of-range input and returns `{:error, :invalid_value}`", context do
      assert Integer.validate(context.test_integer, 13) == {:error, :invalid_value}
      assert Integer.validate(context.test_integer, -1) == {:error, :invalid_value}
    end
  end

  describe "Integer field type function `cast/2`" do
    setup :test_integer

    test "receives valid string input and returns `{:ok, <value>}`", context do
      assert Integer.cast(context.test_integer, "7") == {:ok, 7}
    end

    test "receives valid integer input and returns `{:ok, <value>}`", context do
      assert Integer.cast(context.test_integer, 7) == {:ok, 7}
    end

    test "receives invalid input and returns `{:error, :wrong_type}`", context do
      assert Integer.cast(context.test_integer, "2.") == {:error, :wrong_type}
      assert Integer.cast(context.test_integer, "1.0") == {:error, :wrong_type}
      assert Integer.cast(context.test_integer, 9.0) == {:error, :wrong_type}
      assert Integer.cast(context.test_integer, "fish") == {:error, :wrong_type}
      assert Integer.cast(context.test_integer, %{value: 4}) == {:error, :wrong_type}
    end

    test "receives integer string input that is invalid for the field definition and returns `{:error, :invalid_value}`",
         context do
      assert Integer.cast(context.test_integer, "4") == {:error, :invalid_value}
    end

    test "receives integer input that is invalid for the field definition and returns `{:error, :invalid_value}`",
         context do
      assert Integer.cast(context.test_integer, 6) == {:error, :invalid_value}
    end
  end
end
