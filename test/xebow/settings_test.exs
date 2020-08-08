defmodule Xebow.SettingsTest do
  use ExUnit.Case

  alias Xebow.Settings

  @settings_path Application.compile_env!(:xebow, :settings_path)

  @animations_path Path.join(@settings_path, "animations.json")

  defmodule MockAnimations.Type1 do
  end

  defmodule MockAnimations.Type2 do
  end

  setup do
    File.mkdir_p!(@settings_path)
    on_exit(fn -> File.rm_rf(@settings_path) end)
  end

  test "can create a settings directory" do
    File.rm_rf(@settings_path)

    refute File.exists?(@settings_path)

    :ok = Settings.create_dir!()

    assert File.exists?(@settings_path)
  end

  test "can check if the animation settings file exists" do
    File.rm_rf(@animations_path)
    refute Settings.active_animations_file_exists?()

    File.write!(@animations_path, "")

    assert Settings.active_animations_file_exists?()
  end

  describe "animation settings" do
    test "can be saved" do
      animation_types = [
        MockAnimations.Type1,
        MockAnimations.Type2
      ]

      expected_payload = %{
        "schema_version" => 1,
        "active_animation_types" => [
          "Elixir.Xebow.SettingsTest.MockAnimations.Type1",
          "Elixir.Xebow.SettingsTest.MockAnimations.Type2"
        ]
      }

      Settings.save_active_animations!(animation_types)
      assert File.exists?(@animations_path)

      payload = File.read!(@animations_path) |> Jason.decode!()
      assert payload == expected_payload
    end

    test "can be loaded" do
      animation_types = [
        MockAnimations.Type1,
        MockAnimations.Type2
      ]

      Settings.save_active_animations!(animation_types)

      assert Settings.load_active_animations() == {:ok, animation_types}
    end

    test "load returns error if file doesn't exist" do
      File.rm(@animations_path)
      refute File.exists?(@animations_path)

      assert Settings.load_active_animations() == {:error, :enoent}
    end

    test "load returns error on schema version mismatch" do
      payload =
        %{
          schema_version: -1,
          active_animation_types: []
        }
        |> Jason.encode_to_iodata!()

      File.write!(@animations_path, payload)

      assert Settings.load_active_animations() == {:error, :schema_mismatch}
    end

    test "load ignores invalid animations" do
      Settings.save_active_animations!([
        MockAnimations.Type1,
        "bogus.animation"
      ])

      expected_animations = [MockAnimations.Type1]

      assert Settings.load_active_animations() == {:ok, expected_animations}
    end
  end
end
