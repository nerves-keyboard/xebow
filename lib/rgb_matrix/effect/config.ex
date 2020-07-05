defmodule RGBMatrix.Effect.Config do
  @callback schema() :: keyword(any)
  @callback new(%{optional(atom) => any}) :: struct
  @callback update(struct, %{optional(atom) => any}) :: struct

  @types %{
    integer: RGBMatrix.Effect.Config.Integer,
    option: RGBMatrix.Effect.Config.Option
  }

  defmacro __using__(_) do
    quote do
      import RGBMatrix.Effect.Config

      Module.register_attribute(__MODULE__, :fields,
        accumulate: true,
        persist: false
      )

      @before_compile RGBMatrix.Effect.Config
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
      @behaviour RGBMatrix.Effect.Config

      @enforce_keys unquote(keys)
      defstruct unquote(keys)

      @impl RGBMatrix.Effect.Config
      def schema do
        unquote(schema)
      end

      @impl RGBMatrix.Effect.Config
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

      @impl RGBMatrix.Effect.Config
      def update(config, params) do
        schema = schema()

        Enum.reduce(params, config, fn {key, value}, config ->
          %mod{} = type = Keyword.fetch!(schema, key)
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
