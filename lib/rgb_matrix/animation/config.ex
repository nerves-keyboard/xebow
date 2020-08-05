defmodule RGBMatrix.Animation.Config do
  @moduledoc """
  Provides a behaviour and macros for defining animation configurations.
  """

  # An animation config is a struct, but we don't know ahead of time all the
  # concrete types of struct it might be. (e.g.:
  # RGBMatrix.Animation.HueWave.Config.t)

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

    quote do
      defmodule Config do
        @moduledoc false

        @behaviour unquote(__MODULE__)

        @enforce_keys unquote(keys)
        defstruct unquote(keys)

        @impl true
        def schema do
          unquote(schema)
        end

        @impl true
        def new(params \\ %{}) do
          schema = schema()
          unquote(__MODULE__).new_config(__MODULE__, schema, params)
        end

        @impl true
        def update(config, params) do
          schema = schema()
          unquote(__MODULE__).update_config(config, schema, params)
        end
      end
    end
  end

  @spec new_config(module :: module, schema :: any, %{}) :: t
  def new_config(module, schema, params) do
    schema
    |> Map.new(&validate_field(&1, params))
    |> create_struct!(module)
  end

  @spec update_config(config :: t, schema :: any, params :: %{}) :: t
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
