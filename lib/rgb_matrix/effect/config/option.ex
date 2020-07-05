defmodule RGBMatrix.Effect.Config.Option do
  @enforce_keys [:default, :options]
  defstruct [:default, :options]

  def validate(option, value) do
    if value in option.options do
      :ok
    else
      :error
    end
  end

  def cast(option, bin_value) when is_binary(bin_value) do
    try do
      value = String.to_existing_atom(bin_value)
      cast(option, value)
    rescue
      ArgumentError -> :error
    end
  end

  def cast(option, value) when is_atom(value) do
    case validate(option, value) do
      :ok -> {:ok, value}
      :error -> :error
    end
  end

  def cast(_option, _value), do: :error
end
