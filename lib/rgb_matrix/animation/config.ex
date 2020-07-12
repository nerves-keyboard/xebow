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

  @types %{
    integer: RGBMatrix.Animation.Config.FieldType.Integer,
    option: RGBMatrix.Animation.Config.FieldType.Option
  }

  defmacro __using__(_) do
    quote do
      import RGBMatrix.Animation.Config

      Module.register_attribute(__MODULE__, :fields,
        accumulate: true,
        persist: false
      )

      @before_compile RGBMatrix.Animation.Config
    end
  end

  defmacro field(name, type, opts \\ []) do
    type = Map.fetch!(@types, type)
    type_schema = Macro.escape(struct!(type, opts))

    quote do
      @fields {unquote(name), unquote(type_schema)}
    end
  end

  defmacro __before_compile__(env) do
    schema = Module.get_attribute(env.module, :fields)
    keys = Keyword.keys(schema)
    schema = Macro.escape(schema)

    quote do
      @behaviour RGBMatrix.Animation.Config

      @enforce_keys unquote(keys)
      defstruct unquote(keys)

      @impl RGBMatrix.Animation.Config
      def schema do
        unquote(schema)
      end

      @impl RGBMatrix.Animation.Config
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

      @impl RGBMatrix.Animation.Config
      def update(config, params) do
        schema = schema()

        Enum.reduce(params, config, fn {key, value}, config ->
          # TODO: better key casting
          key = String.to_existing_atom(key)
          %mod{} = type = Keyword.fetch!(schema, key)
          # TODO: better value casting
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
