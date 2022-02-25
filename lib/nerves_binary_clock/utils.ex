defmodule NervesBinaryClock.Utils do
  @moduledoc false

  @default_brightness 0x060

  @doc """
  Converts the provided number to zero-padded bit list.

  ## Examples

      iex> padded_bits(3, 6)
      [0, 0, 0, 0, 1, 1]

  """
  @spec padded_bits(non_neg_integer, non_neg_integer) :: [0 | 1]
  def padded_bits(number, total_length \\ 6) do
    number
    |> Integer.digits(2)
    |> zero_pad_list(total_length)
  end

  @doc """
  Zero-pads a number list.

  ## Examples

      iex> zero_pad_list([1, 2, 3], 6)
      [0, 0, 0, 1, 2, 3]

  """
  @spec zero_pad_list([non_neg_integer], non_neg_integer) :: [0 | 1]
  def zero_pad_list(numbers, total_length \\ 6) do
    padding = List.duplicate(0, total_length - length(numbers))
    padding ++ numbers
  end

  @doc """
  Formats a list of zeros and ones.

  ## Examples

      iex> formatter([1, 0, 1, 1], :none)
      [1, 0, 1, 1]

      iex> formatter([1, 0, 1, 1], :bytes)
      <<0x060::12, 0x060::12, 0x000::12, 0x060::12>>

      iex> formatter([1, 0, 1, 1], :pretty)
      "*-**"

  """
  @spec formatter([0 | 1], :bytes | :none | :pretty, keyword) :: list | bitstring | String.t()
  def formatter(list, format_type, opts \\ [])
  def formatter(list, :none, _opts), do: list
  def formatter(list, :bytes, opts), do: to_bytes(list, opts)
  def formatter(list, :pretty, opts), do: to_pretty_bytes(list, opts)

  @doc """
  Converts a list of zeros and ones to a 12-bit bit string. The order is least chanel number first.

  ## Examples

      # ch 0: on
      # ch 1: on
      # ch 2: off
      # ch 3: on
      iex> to_bytes([1, 0, 1, 1])
      <<0x060::12, 0x060::12, 0x000::12, 0x060::12>>

      iex> to_bytes([1, 0, 1, 1], brightness: 0xfff)
      <<0xfff::12, 0xfff::12, 0x000::12, 0xfff::12>>

  """
  @spec to_bytes([0 | 1], keyword()) :: bitstring
  def to_bytes(list, opts \\ []) do
    brightness = opts[:brightness] || @default_brightness
    for bit <- Enum.reverse(list), into: <<>>, do: to_bitstring(bit, brightness)
  end

  defp to_bitstring(0, _brightness), do: <<0::12>>
  defp to_bitstring(1, brightness), do: <<brightness::12>>

  @doc """
  Converts a list of zeros and ones to a pretty string representation.

  ## Examples

      iex> to_pretty_bytes([1, 0, 1, 1])
      "*-**"

  """
  @spec to_pretty_bytes([0 | 1], keyword()) :: String.t()
  def to_pretty_bytes(list, _opts \\ []) when is_list(list) do
    for bit <- list, into: "", do: to_pretty_led_value(bit)
  end

  defp to_pretty_led_value(0), do: "-"
  defp to_pretty_led_value(1), do: "*"
end
