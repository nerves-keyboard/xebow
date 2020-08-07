defmodule Xebow.Settings do
  @moduledoc """
  Application settings that are persisted to disk.
  """

  @settings_path Application.compile_env!(:xebow, :settings_path)

  @doc """
  Create the directory for the settings files. This function is idempotent.
  """
  @spec create_dir!() :: :ok
  def create_dir! do
    File.mkdir_p!(@settings_path)
  end
end
