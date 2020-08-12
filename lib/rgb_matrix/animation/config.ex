defmodule RGBMatrix.Animation.Config do
  @moduledoc """
  Provides a behaviour and macros for defining animation configurations.
  """

  alias __MODULE__.FieldType

  require Logger

  @field_types %{
    integer: FieldType.Integer,
    option: FieldType.Option
  }

  @typedoc """
  A `Config` is a struct representing a config for a specific animation.
  concrete types of struct it might be. (e.g.:
  RGBMatrix.Animation.HueWave.Config.t)
  """
  @type t :: struct

  @typedoc """
  A `config_schema` is a keyword list containing the configuration fields for
  an animation type.

  It provides the defaults for each field, the available
  parameters to configure (such as `:default`, `:min`, `:options`, and so on),
  and can provide `:doc`, a keyword list, for documentation such as a
  human-readable `:name` and `:description`.

  The keys are defined by the first atom provided to an Animation's `field`
  definition(s). The values are `Config.FieldType` types.

  The documentation is not guaranteed to exist. It will be an empty list, in
  that case.
  """
  @type config_schema :: keyword(FieldType.t())

  @typedoc """
  `creation_params` is a map used during creation of an
  `Animation.<type>.Config`.

  The keys are defined by the first atom provided to an Animation's `field`
  definition(s) and must be one of `#{inspect(Map.keys(@field_types))}`.

  The value should be appropriate for the field.
  """
  @type creation_params :: %{optional(atom) => FieldType.value()}

  @typedoc """
  The possible error atoms during creation and update of configs
  """
  @type field_error ::
          :cast_error
          | :error
          | :invalid_field
          | :validation_error

  @typedoc """
  A `schema_field` is a tuple of the form `{name, %FieldType.t}`.

  `name` is one of `#{inspect(Map.keys(@field_types))}`
  """
  @type schema_field :: {name :: atom, FieldType.t()}

  @typedoc """
  `update_params` is a map used to update an `Animation.<type>.Config`.

  The key is defined by the first atom provided to an Animation's `field`
  definition(s) and must be one of `#{inspect(Map.keys(@field_types))}`.
  The key may be a string or an atom.

  The value should be appropriate for the field.
  """
  @type update_params :: %{(atom | String.t()) => any}

  @callback schema() :: config_schema
  @callback new(%{optional(atom) => FieldType.value()}) :: t
  @callback update(t, %{optional(atom | String.t()) => any}) :: t

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
  Creates a new %Config{} struct belonging to the provided
  `Animation.<type>.Config` module.

  The provided Config must be defined through the `use Animation` and `field`
  macros in an Animation.<type> module.

  Returns a %Config{} struct.

  Example:
      iex> RGBMatrix.Animation.Config.new_config(
      ...>   RGBMatrix.Animation.HueWave.Config,
      ...>   RGBMatrix.Animation.HueWave.Config.schema(),
      ...>   %{})
      %RGBMatrix.Animation.HueWave.Config{direction: :right, speed: 4, width: 20}
  """
  @spec new_config(
          module :: module,
          schema :: config_schema,
          params :: creation_params
        ) :: t
  def new_config(module, schema, params) do
    schema
    |> Enum.map(fn schema_field -> validate_field(schema_field, params) end)
    |> Map.new()
    |> create_struct!(module)
  end

  @doc """
  Updates the provided %Config{} struct using the provided schema and params map.

  Returns the updated config.

  Example:
      iex> RGBMatrix.Animation.Config.update_config(
      ...>   hue_wave_config,
      ...>   RGBMatrix.Animation.HueWave.Config.schema(),
      ...>   %{"direction" => "left"})
      %RGBMatrix.Animation.HueWave.Config{direction: :left, speed: 4, width: 20}
  """
  @spec update_config(
          config :: t,
          schema :: config_schema,
          params :: update_params
        ) :: t
  def update_config(config, schema, params) do
    params
    |> Enum.reduce(config, fn param, config ->
      cast_and_update_field(param, config, schema)
    end)
  end

  @spec cast_and_update_field(
          param :: {atom | String.t(), any},
          config :: t,
          schema :: config_schema
        ) :: t
  defp cast_and_update_field({key, value} = _param, config, schema) do
    with key <- create_atom_key(key),
         {:ok, %type_module{} = type} <- Keyword.fetch(schema, key),
         {:ok, value} <- type_module.cast(type, value) do
      Map.put(config, key, value)
    else
      error ->
        field_warn(error, key, value)
        config
    end
  end

  @spec validate_field(schema_field, creation_params) ::
          {atom, FieldType.field()} | nil
  defp validate_field({key, %type_module{} = type} = _field, params) do
    value = Map.get(params, key, type.default)

    case type_module.validate(type, value) do
      :ok ->
        {key, value}

      error ->
        field_warn(error, key, value)
        {key, type.default}
    end
  end

  @spec create_atom_key(key :: atom | String.t()) ::
          (key :: atom) | :invalid_field
  defp create_atom_key(key) when is_atom(key), do: key

  defp create_atom_key(key) when is_binary(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError ->
      :invalid_field
  end

  @spec create_struct!(map, module) :: struct
  defp create_struct!(map, module), do: struct!(module, map)

  @spec field_warn(
          error :: field_error,
          key :: atom | String.t(),
          value :: any
        ) :: :ok
  defp field_warn(:cast_error, key, value) do
    Logger.warn("#{inspect(value)} is not the correct type for #{key}")
  end

  defp field_warn(:error, key, _value) do
    Logger.warn("#{inspect(key)} is an invalid field identifier")
  end

  defp field_warn(:invalid_field, key, _value) do
    Logger.warn("#{inspect(key)} is an invalid field identifier")
  end

  defp field_warn(:validation_error, key, value) do
    Logger.warn("#{inspect(value)} is an invalid value for #{key}")
  end
end
