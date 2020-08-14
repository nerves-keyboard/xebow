defmodule Xebow.Settings do
  @moduledoc """
  Application settings that are persisted to disk.
  """

  alias RGBMatrix.Animation

  require Logger

  @settings_path Application.compile_env!(:xebow, :settings_path)

  @animations_path Path.join(@settings_path, "animations.json")

  @animations_version 1

  @doc """
  Create the directory for the settings files. This function is idempotent.
  """
  @spec create_dir!() :: :ok
  def create_dir! do
    File.mkdir_p!(@settings_path)
  end

  @doc """
  Save the active animations to disk.
  """
  @spec save_active_animations!(animation_types :: [Animation.type()]) :: :ok
  def save_active_animations!(animation_types) do
    create_dir!()

    payload =
      Jason.encode_to_iodata!(%{
        schema_version: @animations_version,
        active_animation_types: animation_types
      })

    File.write!(@animations_path, payload)
  end

  @doc """
  Load the active animations from disk.
  """
  @spec load_active_animations() ::
          {:ok, [Animation.type()]}
          | {:error, File.posix()}
          | {:error, :schema_mismatch}
  def load_active_animations do
    with {:ok, payload} <- File.read(@animations_path),
         animation_settings <- Jason.decode!(payload),
         :ok <- validate_schema(animation_settings, @animations_version) do
      animation_types =
        animation_settings["active_animation_types"]
        |> Enum.map(&cast_animation_type/1)
        |> Enum.reject(&is_nil/1)

      {:ok, animation_types}
    else
      error -> error
    end
  end

  @doc """
  Returns true if the active animations settings file exists.
  """
  @spec active_animations_file_exists?() :: boolean
  def active_animations_file_exists? do
    File.exists?(@animations_path)
  end

  defp cast_animation_type(animation_type) do
    try do
      String.to_existing_atom(animation_type)
    rescue
      ArgumentError ->
        Logger.warn("Ignoring invalid animation setting: #{animation_type}")
        nil
    end
  end

  defp validate_schema(settings, expected_version) do
    if settings["schema_version"] == expected_version do
      :ok
    else
      {:error, :schema_mismatch}
    end
  end
end
