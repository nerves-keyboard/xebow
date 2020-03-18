defmodule Xebow.Utils do
  @moduledoc """
  Shared utility functions that are generally useful.
  """

  @doc """
  Modulo operation that supports negative numbers.

  This is effectively `mod` as it exists in most other languages. Elixir's `rem`
  doesn't act the same as other languages for negative numbers.
  """
  @spec mod(integer, integer) :: non_neg_integer
  def mod(number, modulus) when is_integer(number) and is_integer(modulus) do
    case rem(number, modulus) do
      remainder when (remainder > 0 and modulus < 0) or (remainder < 0 and modulus > 0) ->
        remainder + modulus

      remainder ->
        remainder
    end
  end

  @doc """
  Pads a matrix that isn't fully complete with `nil`s.
  Assumes the first row is complete, and all subsequent rows are either complete
  or shorter than the first.
  ## Examples
      iex> pad_matrix([[1, 2, 3], [4, 5, 6], [7]])
      [[1, 2, 3], [4, 5, 6], [7, nil, nil]]
      iex> pad_matrix([[1, 2, 3], [4, 5], [6]])
      [[1, 2, 3], [4, 5, nil], [6, nil, nil]]
  """
  def pad_matrix([first | _rest] = matrix) do
    length = Enum.count(first)

    Enum.map(matrix, fn row ->
      if Enum.count(row) != length do
        [[], padded] =
          Enum.reduce(1..length, [row, []], fn
            _, [[], acc] -> [[], [nil | acc]]
            _, [[next | rest], acc] -> [rest, [next | acc]]
          end)

        Enum.reverse(padded)
      else
        row
      end
    end)
  end

  @doc """
  Dedupes a list of key press and release events.
  ## Examples
      iex> dedupe_events([pressed: :k001, released: :k001])
      []
      iex> dedupe_events([released: :k001, pressed: :k001])
      []
      iex> dedupe_events([pressed: :k001, released: :k001, pressed: :k001])
      [pressed: :k001]
      iex> dedupe_events([released: :k001, pressed: :k001, released: :k001])
      [released: :k001]
      iex> dedupe_events([pressed: :k001, pressed: :k002, released: :k001])
      [pressed: :k002]
      iex> dedupe_events([pressed: :k001, pressed: :k002, released: :k002, released: :k001])
      []
      iex> dedupe_events([released: :k002, released: :k001, pressed: :k002, pressed: :k001])
      []
  """
  def dedupe_events(events) do
    events
    |> Enum.reduce([], fn {type, key}, acc ->
      opposite = opposite(type)

      case Keyword.get(acc, key) do
        nil -> [{key, type} | acc]
        ^opposite -> Keyword.delete(acc, key)
      end
    end)
    |> Enum.reduce([], fn {x, y}, acc -> [{y, x} | acc] end)
  end

  defp opposite(:pressed), do: :released
  defp opposite(:released), do: :pressed
end
