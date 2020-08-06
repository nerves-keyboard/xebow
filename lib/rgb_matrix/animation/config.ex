defmodule RGBMatrix.Animation.Config do
  @moduledoc """
  Provides a behaviour and macros for defining animation configurations.
  """

  @typedoc """
  An animation config is a struct, but we don't know ahead of time all the
  concrete types of struct it might be. (e.g.:
  RGBMatrix.Animation.HueWave.Config.t)
  """
  @type t :: struct
  @type field_type :: [
          __MODULE__.FieldType.Integer
          | __MODULE__.FieldType.Option
        ]

  @callback schema() :: keyword(any)
  @callback new(%{optional(atom) => any}) :: t
  @callback update(t, %{optional(atom) => any}) :: t

  @field_types %{
    integer: __MODULE__.FieldType.Integer,
    option: __MODULE__.FieldType.Option
  }

  @doc """
  Returns the map of field types provided by the Config module
  """
  @spec field_types :: %{atom => any}
  def field_types, do: @field_types

  defmacro __before_compile__(env) do
    schema = Module.get_attribute(env.module, :fields)
    keys = Keyword.keys(schema)
    schema = Macro.escape(schema)
    config_module = __MODULE__

    quote do
      defmodule Config do
        @moduledoc false

        @behaviour unquote(config_module)

        @enforce_keys unquote(keys)
        defstruct unquote(keys)

        @impl true
        def schema do
          unquote(schema)
        end

        @impl true
        def new(params \\ %{}) do
          schema = schema()
          unquote(config_module).new_config(__MODULE__, schema, params)
        end

        @impl true
        def update(config, params) do
          schema = schema()
          unquote(config_module).update_config(config, schema, params)
        end
      end
    end
  end

  @doc """
  Creates a new %Config{} struct belonging to the provided Animation.<type>.Config
  module.

  The provided Config must be defined through the `use Animation` and `field`
  macros in an Animation.<type> module.

  Returns a %Config{} struct.

  Example:
      iex> RGBMatrix.Animation.Config.new_config(
      ...>   RGBMatrix.Animation.HueWave.Config,
      ...>   RGBMatrix.Animation.HueWave.Config.schema(),
      ...>   %{}
      ...> )
      %RGBMatrix.Animation.HueWave.Config{direction: :right, speed: 4, width: 20}
  """
  @spec new_config(module :: module, schema :: any, params :: map) :: t
  def new_config(module, schema, params) do
    schema
    |> Map.new(&validate_field(&1, params))
    |> create_struct!(module)
  end

  @doc """
  Updates the provided %Config{} struct using the provided schema and params map.

  Returns the updated config.

  Example:
      iex> RGBMatrix.Animation.Config.update_config(
      ...>   hue_wave_config,
      ...>   RGBMatrix.Animation.HueWave.Config.schema(),
      ...>   %{"direction" => "left"}
      ...> )
      %RGBMatrix.Animation.HueWave.Config{direction: :left, speed: 4, width: 20}
  """
  @spec update_config(config :: t, schema :: any, params :: map) :: t
  def update_config(config, schema, params) do
    Enum.reduce(params, config, &update_field(&1, &2, schema))
  end

  defp create_atom_key(key) when is_binary(key), do: String.to_existing_atom(key)
  defp create_atom_key(key) when is_atom(key), do: key

  defp create_struct!(map, module), do: struct!(module, map)

  defp update_field({key, value}, config, schema) do
    key = create_atom_key(key)

    %type_module{} = type = Keyword.fetch!(schema, key)
    {:ok, value} = type_module.cast(type, value)
    if type_module.validate(type, value) == :error, do: value_error!(value, key)

    Map.put(config, key, value)
  end

  defp validate_field({key, %type_module{} = type}, params) do
    value = Map.get(params, key, type.default)

    case type_module.validate(type, value) do
      :ok -> {key, value}
      :error -> value_error!(value, key)
    end
  end

  defp value_error!(value, key) do
    message = "#{__MODULE__}: value `#{inspect(value)}` is invalid for config option `#{key}`."

    raise ArgumentError, message: message
  end
end
