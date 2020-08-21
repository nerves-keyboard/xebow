defmodule ConfigTest do
  use ExUnit.Case

  alias RGBMatrix.Animation.Config.FieldType.{Integer, Option}

  defmodule MockConfig do
    @fields [
      test_integer: %Integer{
        default: 5,
        min: 0,
        max: 10
      },
      test_option: %Option{
        default: :a,
        options: ~w(a b)a
      }
    ]
    @before_compile RGBMatrix.Animation.Config
  end

  defp make_test_config do
    RGBMatrix.Animation.Config.new_config(
      MockConfig.Config,
      MockConfig.Config.schema(),
      %{}
    )
  end

  describe "Animation configurations" do
    test "can be created with integer and option types" do
      assert %MockConfig.Config{test_integer: 5, test_option: :a} == make_test_config()
    end

    test "can be updated" do
      mock_config = make_test_config()

      assert %MockConfig.Config{test_integer: 8, test_option: :a} ==
               RGBMatrix.Animation.Config.update_config(
                 mock_config,
                 MockConfig.Config.schema(),
                 %{"test_integer" => "8"}
               )

      assert %MockConfig.Config{test_integer: 5, test_option: :b} ==
               RGBMatrix.Animation.Config.update_config(
                 mock_config,
                 MockConfig.Config.schema(),
                 %{"test_option" => "b"}
               )
    end
  end
end
