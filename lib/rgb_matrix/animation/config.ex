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
  A struct containing runtime configuration for a specific animation.

  Example:
      RGBMatrix.Animation.HueWave.Config
      RGBMatrix.Animation.SolidReactive.Config

  Configs should not be accessed or modified directly in an Animation module.
  Use the functions `Xebow.get_animation_config/0` and
  `Xebow.update_animation_config/1` for access and modification.
  """
  @type t :: struct

  @typedoc """
  A keyword list containing the configuration fields for an animation type.

  It provides the defaults for each field, the available parameters to configure
  (such as `:default`, `:min`, `:options`, and so on). It can provide `:doc`, a
  keyword list, for documentation such as a human-readable `:name` and
  `:description`.

  The keys are defined by the first atom, the name, provided to an Animation's
  `field` definition(s). The values are
  `t:RGBMatrix.Animation.Config.FieldType.t/0` types.

  The documentation is optional and will be initialized to an empty list if
  omitted.
  """
  @type schema :: keyword(FieldType.t())

  @typedoc """
  A map used during creation of an `Animation.<type>.Config`.

  The keys are defined by the first atom, the name, provided to an Animation's
  `field` definition(s) and must match the field being defined.

  The value should be appropriate for the specified field.
  """
  @type creation_params :: %{optional(atom) => FieldType.value()}

  @typedoc """
  A tuple of the form, `{name, field}`. `name` is one of the valid
  `FieldType` names and `field` is a
  `t:RGBMatrix.Animation.Config.FieldType.t/0` struct.
  """
  @type schema_field :: {name :: atom, FieldType.t()}

  @typedoc """
  A map used to update an `Animation.<type>.Config`.

  The keys are defined by the first atom, the name, provided to an Animation's
  `field` definition(s) and must match the field(s) being updated. The key may
  be a string or an atom.

  The value should be appropriate for the field.
  """
  @type update_params :: %{(atom | String.t()) => any}

  @callback schema() :: schema
  @callback new(%{optional(atom) => FieldType.value()}) :: t
  @callback update(t, %{optional(atom | String.t()) => any}) :: t

  @doc """
  Returns a map of field types provided by the Config module
  """
  @spec field_types :: %{atom => FieldType.submodule()}
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
  Creates a new `t:t/0` struct belonging to the provided
  `Animation.<type>.Config` module.

  The provided Config must be defined through the `use Animation` and `field`
  macros in an `Animation.<type>` module.

  The params provided are a map of `t:creation_params/0`.

  Returns a `t:t/0` struct.

  Example:
      iex> module = RGBMatrix.Animation.HueWave.Config
      iex> schema = module.schema()
      iex> params = %{direction: :up, width: 30}
      iex> RGBMatrix.Animation.Config.new_config(module, schema, params)
      %RGBMatrix.Animation.HueWave.Config{direction: :up, speed: 4, width: 30}

  The above example shows setting the direction and width to non-default values.

  Any invalid keys in the `t:creation_params/0` map will cause that param to be
  ignored. Invalid values for fields will be ignored. In both cases, the default
  provided to the type will be used as the initial value for that field.

  All errors will be logged.
  """
  @spec new_config(
          module :: module,
          schema :: schema,
          params :: creation_params
        ) :: t
  def new_config(module, schema, params) do
    schema =
      schema
      |> Enum.map(fn schema_field -> validate_field(schema_field, params) end)
      |> Map.new()

    struct!(module, schema)
  end

  @doc """
  Updates the provided `t:t/0` struct using the provided schema and params.

  The params are a map of `t:update_params/0`.

  Configs must be retrieved through the use of `Xebow.get_animation_config/0`,
  which will return both the config and the schema.

  Returns the updated `t:t/0` struct.

  Example:
      iex> {config, schema} = Xebow.get_animation_config()
      iex> params = %{"direction" => "left", speed: 8}
      iex> RGBMatrix.Animation.Config.update_config(config, schema, params)
      %RGBMatrix.Animation.HueWave.Config{direction: :left, speed: 8, width: 20}

  The above example shows updating the direction and speed.

  Any errors encountered during update are logged, and the struct is returned
  unchanged.
  """
  @spec update_config(
          config :: t,
          schema :: schema,
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
          schema :: schema
        ) :: t
  defp cast_and_update_field({key, value} = _param, config, schema) do
    with {:ok, key} <- create_atom_key(key),
         {:ok, %type_module{} = type} <- fetch_type_from_schema(schema, key),
         {:ok, value} <- type_module.cast(type, value) do
      Map.put(config, key, value)
    else
      {:error, reason} ->
        field_warn(reason, key, value)
        config
    end
  end

  @spec validate_field(schema_field, creation_params) :: {atom, FieldType.value()}
  defp validate_field({key, %type_module{} = type} = _schema_field, params) do
    value = Map.get(params, key, type.default)

    case type_module.validate(type, value) do
      :ok ->
        {key, value}

      {:error, reason} ->
        field_warn(reason, key, value)
        {key, type.default}
    end
  end

  @spec create_atom_key(key :: atom) ::
          {:ok, key :: atom} | {:error, :undefined_field}
  defp create_atom_key(key) when is_atom(key), do: {:ok, key}

  @spec create_atom_key(key :: String.t()) ::
          {:ok, key :: atom} | {:error, :undefined_field}
  defp create_atom_key(key) when is_binary(key) do
    {:ok, String.to_existing_atom(key)}
  rescue
    ArgumentError ->
      {:error, :undefined_field}
  end

  @spec fetch_type_from_schema(schema, atom) ::
          {:ok, FieldType.t()} | {:error, :undefined_field}
  defp fetch_type_from_schema(schema, key) do
    case Keyword.fetch(schema, key) do
      {:ok, type} -> {:ok, type}
      :error -> {:error, :undefined_field}
    end
  end

  @spec field_warn(
          reason :: FieldType.error(),
          key :: atom | String.t(),
          value :: any
        ) :: :ok
  defp field_warn(:wrong_type, key, value) do
    Logger.warn("#{inspect(value)} is not the correct type for #{key}")
  end

  defp field_warn(:undefined_field, key, _value) do
    Logger.warn("#{inspect(key)} is an undefined field identifier")
  end

  defp field_warn(:invalid_value, key, value) do
    Logger.warn("#{inspect(value)} is an invalid value for #{key}")
  end
end
