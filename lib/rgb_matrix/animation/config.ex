defmodule RGBMatrix.Animation.Config do
  @moduledoc """
  Provides a behaviour and macros for defining animation configurations.
  """

  # An animation config is a struct, but we don't know ahead of time all the
  # concrete types of struct it might be. (e.g.:
  # RGBMatrix.Animation.HueWave.Config.t)
  @type t :: struct

  @callback schema() :: keyword(any)
  @callback new(%{optional(atom) => any}) :: t
  @callback update(t, %{optional(atom) => any}) :: t

  @optional_callbacks [new: 1]

  Module.register_attribute(__MODULE__, :field_types, persist: true)

  @field_types %{
    integer: __MODULE__.FieldType.Integer,
    option: __MODULE__.FieldType.Option
  }

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
          schema()
          |> Map.new(fn {key, %mod{} = type} ->
            value = Map.get(params, key, type.default)

            case mod.validate(type, value) do
              :ok -> {key, value}
              :error -> value_error!(value, key)
            end
          end)
          |> (&struct!(__MODULE__, &1)).()
        end

        @impl true
        def update(config, params) do
          schema = schema()

          Enum.reduce(params, config, fn {key, value}, config ->
            key = String.to_existing_atom(key)
            %mod{} = type = Keyword.fetch!(schema, key)
            {:ok, value} = mod.cast(type, value)
            if mod.validate(type, value) == :error, do: value_error!(value, key)

            Map.put(config, key, value)
          end)
        end

        defp value_error!(value, key) do
          message =
            "#{__MODULE__}: value `#{inspect(value)}` is invalid for config option `#{key}`."

          raise ArgumentError, message: message
        end
      end
    end
  end
end
