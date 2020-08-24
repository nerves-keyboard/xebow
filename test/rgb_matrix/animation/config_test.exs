defmodule ConfigTest do
  use ExUnit.Case

  alias RGBMatrix.Animation.Config
  alias RGBMatrix.Animation.Config.FieldType.{Integer, Option}

  import ExUnit.CaptureLog

  defmodule MockConfig do
    @fields [
      test_integer: %Integer{
        default: 5,
        min: 1,
        max: 11,
        step: 2
      },
      test_option: %Option{
        default: :default,
        options: ~w(default non_default)a
      }
    ]
    @before_compile Config
  end

  defp make_test_config(module, params \\ %{}) do
    Config.new_config(
      Module.concat(module, "Config"),
      Module.concat(module, "Config").schema(),
      params
    )
  end

  defp test_config(_context) do
    test_config = make_test_config(MockConfig)
    test_schema = MockConfig.Config.schema()
    [test_config: test_config, test_schema: test_schema]
  end

  describe "an animation configuration created using new_config/3" do
    test "can be created with integer and option types and empty params" do
      assert make_test_config(MockConfig, %{}) ==
               %MockConfig.Config{
                 test_integer: 5,
                 test_option: :default
               }
    end

    test "can be created with a non-default value for an Integer" do
      assert make_test_config(MockConfig, %{test_integer: 3}) ==
               %MockConfig.Config{
                 test_integer: 3,
                 test_option: :default
               }
    end

    test "can be created with a non-default value for an Option" do
      assert make_test_config(MockConfig, %{test_option: :non_default}) ==
               %MockConfig.Config{
                 test_integer: 5,
                 test_option: :non_default
               }
    end

    test "can be created with a non-default value for multiple fields" do
      assert make_test_config(MockConfig, %{test_integer: 3, test_option: :non_default}) ==
               %MockConfig.Config{
                 test_integer: 3,
                 test_option: :non_default
               }
    end

    test "will ignore invalid values for Integer fields" do
      output =
        capture_log(fn ->
          assert make_test_config(MockConfig, %{test_integer: "fish"}) ==
                   %MockConfig.Config{
                     test_integer: 5,
                     test_option: :default
                   }
        end)

      assert output =~ "\"fish\" is an invalid value for test_integer"
    end

    test "will ignore invalid values for Option fields" do
      output =
        capture_log(fn ->
          assert make_test_config(MockConfig, %{test_option: :invalid}) ==
                   %MockConfig.Config{
                     test_integer: 5,
                     test_option: :default
                   }
        end)

      assert output =~ ":invalid is an invalid value for test_option"
    end

    test "will ignore multiple invalid field values" do
      output =
        capture_log(fn ->
          assert make_test_config(MockConfig, %{test_integer: "dog", test_option: :invalid}) ==
                   %MockConfig.Config{
                     test_integer: 5,
                     test_option: :default
                   }
        end)

      assert output =~ "\"dog\" is an invalid value for test_integer"
      assert output =~ ":invalid is an invalid value for test_option"
    end
  end

  describe "a correct animation configuration" do
    setup :test_config

    test "can update field types using string key and value", context do
      new_integer_string = "7"
      new_integer = 7

      new_integer_config = %MockConfig.Config{
        test_integer: new_integer,
        test_option: :default
      }

      assert Config.update_config(
               context.test_config,
               context.test_schema,
               %{"test_integer" => new_integer_string}
             ) == new_integer_config
    end

    test "can update field types using atom key and integer value", context do
      new_integer = 7

      new_integer_config = %MockConfig.Config{
        test_integer: new_integer,
        test_option: :default
      }

      assert Config.update_config(
               context.test_config,
               context.test_schema,
               %{:test_integer => new_integer}
             ) == new_integer_config
    end

    test "can update multiple fields simultaneously", context do
      new_integer = 3
      new_option = :non_default

      new_config = %MockConfig.Config{
        test_integer: new_integer,
        test_option: new_option
      }

      assert Config.update_config(
               context.test_config,
               context.test_schema,
               %{test_integer: new_integer, test_option: new_option}
             ) == new_config
    end

    test "will not add additional fields for update_config", context do
      output =
        capture_log(fn ->
          assert Config.update_config(
                   context.test_config,
                   context.test_schema,
                   %{invalid_option: :default}
                 ) == context.test_config
        end)

      assert output =~ ":invalid_option is an undefined field identifier"
    end

    test "will not update with option choices that have not been defined for that field",
         context do
      output =
        capture_log(fn ->
          assert Config.update_config(
                   context.test_config,
                   context.test_schema,
                   %{test_option: :invalid}
                 ) == context.test_config
        end)

      assert output =~ ":invalid is an invalid value for test_option"
    end

    test "will not update with integers out of defined ranges", context do
      output =
        capture_log(fn ->
          assert Config.update_config(
                   context.test_config,
                   context.test_schema,
                   %{test_integer: -10}
                 ) == context.test_config
        end)

      assert output =~ "-10 is an invalid value for test_integer"
    end

    test "will not update with integers that are not a multiple of `step`, adjusted by `min` value",
         context do
      output =
        capture_log(fn ->
          assert Config.update_config(
                   context.test_config,
                   context.test_schema,
                   %{test_integer: 4}
                 ) == context.test_config
        end)

      assert output =~ "4 is an invalid value for test_integer"
    end
  end
end
