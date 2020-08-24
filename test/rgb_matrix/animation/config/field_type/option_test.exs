defmodule OptionTest do
  use ExUnit.Case

  alias RGBMatrix.Animation.Config.FieldType.Option

  defp test_option(_context) do
    [
      test_option: %Option{
        default: :default,
        options: ~w(default non_default valid)a
      }
    ]
  end

  describe "Option field type function `validate/2`" do
    setup :test_option

    test "receives valid atoms for input and returns `:ok`", context do
      assert Option.validate(context.test_option, :default) == :ok
      assert Option.validate(context.test_option, :non_default) == :ok
      assert Option.validate(context.test_option, :valid) == :ok
    end

    test "receives invalid atoms and returns `:validation_error`", context do
      assert Option.validate(context.test_option, :bad_option) == {:error, :invalid_value}
    end
  end

  describe "Option field type function `cast/2`" do
    setup :test_option

    test "receives valid string input and returns `{:ok, <value>}`", context do
      assert Option.cast(context.test_option, "default") == {:ok, :default}
      assert Option.cast(context.test_option, "valid") == {:ok, :valid}
    end

    test "receives valid atom input and returns `{:ok, <value>}`", context do
      assert Option.cast(context.test_option, :non_default) == {:ok, :non_default}
    end

    test "receives invalid string input and returns `{:error, :wrong_type}`", context do
      assert Option.cast(context.test_option, "floop") == {:error, :wrong_type}
    end

    test "receives invalid atom input and returns `{:error, :invalid_value}`", context do
      assert Option.cast(context.test_option, :random_atom) == {:error, :invalid_value}
    end
  end
end
