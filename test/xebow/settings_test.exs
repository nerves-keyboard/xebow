defmodule Xebow.SettingsTest do
  use ExUnit.Case

  alias Xebow.Settings

  @settings_path Application.compile_env!(:xebow, :settings_path)

  setup do
    on_exit(fn -> File.rm_rf!(@settings_path) end)
  end

  test "can create a settings directory" do
    File.rm_rf!(@settings_path)

    refute File.exists?(@settings_path)

    :ok = Settings.create_dir!()

    assert File.exists?(@settings_path)
  end
end
