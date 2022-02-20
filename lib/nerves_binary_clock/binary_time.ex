defmodule NervesBinaryClock.BinaryTime do
  @moduledoc """
  The clock time core logic that translates an Elixir time to LEDs upon request.
  """

  defstruct ~w[ampm hour minute second]a

  @type t :: %__MODULE__{
          ampm: 0 | 1,
          hour: non_neg_integer(),
          minute: non_neg_integer(),
          second: non_neg_integer()
        }

  @default_brightness 0x060

  @doc """
  Takes an Elixir time and converts that time to the accumulator struct.

  ## Examples

      iex> NervesBinaryClock.BinaryTime.new(%{hour: 13,  minute: 34, second: 38})
      %NervesBinaryClock.BinaryTime{ampm: 1, hour: 1, minute: 34, second: 38}

      iex> NervesBinaryClock.BinaryTime.new(%{hour: 13,  minute: 34, second: 38})
      ...> |> NervesBinaryClock.BinaryTime.to_leds(:none)
      [0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0]

      iex> NervesBinaryClock.BinaryTime.new(%{hour: 13,  minute: 34, second: 38})
      ...> |> NervesBinaryClock.BinaryTime.to_leds(:bytes)
      <<0::12, 96::12, 0::12, 0::12, 0::12, 96::12, 96::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 0::12, 96::12, 96::12, 0::12, 0::12, 96::12, 96::12, 0::12>>

      iex> NervesBinaryClock.BinaryTime.new(%{hour: 13,  minute: 34, second: 38})
      ...> |> NervesBinaryClock.BinaryTime.to_leds(:pretty)
      "-**--**----------**---*-"

  """
  @spec new(Time.t()) :: t()
  def new(%{hour: hour, minute: minute, second: second}) do
    %__MODULE__{
      ampm: hour |> div(12),
      hour: hour |> rem(12),
      minute: minute,
      second: second
    }
  end

  @doc """
  Takes a clock struct and converts it to a list of bits for the presentation.
  """
  def to_leds(clock, format_type, opts \\ []) do
    [
      clock.second |> padded_bits |> Enum.reverse(),
      clock.hour |> padded_bits |> Enum.reverse(),
      clock.ampm |> padded_bits,
      clock.minute |> padded_bits
    ]
    |> List.flatten()
    |> formatter(format_type, opts)
  end

  @doc """
  Converts the provided number to zero-padded bit list.

  ## Examples

      iex> padded_bits(3, 6)
      [0, 0, 0, 0, 1, 1]

  """
  @spec padded_bits(non_neg_integer, non_neg_integer) :: [0 | 1]
  def padded_bits(number, total_length \\ 6) do
    bits = Integer.digits(number, 2)
    padding = List.duplicate(0, total_length - length(bits))
    padding ++ bits
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
    for bit <- Enum.reverse(list), into: <<>>, do: to_channel_value_bitstring(bit, brightness)
  end

  defp to_channel_value_bitstring(0, _brightness), do: <<0::12>>
  defp to_channel_value_bitstring(1, brightness), do: <<brightness::12>>

  @doc """
  Converts a list of zeros and ones to a pretty string representation.

  ## Examples

      iex> to_pretty_bytes([1, 0, 1, 1])
      "*-**"

  """
  @spec to_pretty_bytes([0 | 1], keyword()) :: String.t()
  def to_pretty_bytes(list, _opts \\ []) when is_list(list) do
    for bit <- list, into: "", do: to_pretty_channel_value(bit)
  end

  defp to_pretty_channel_value(0), do: "-"
  defp to_pretty_channel_value(1), do: "*"
end
