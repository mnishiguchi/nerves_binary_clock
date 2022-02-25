defmodule NervesBinaryClock.FourDigitSevenSegmentClock.ClockTime do
  @moduledoc """
  The clock time core logic that translates an Elixir time to Seven-segment Four-digit display upon request.

  The user needs to specify their desired mapping between the display pins to TLC5947 channels.

  ```
  rpi ------ TLC5947 ------ display
       SPI    24 channels    12 pins
  ```
  """

  defstruct [
    :display_type,
    :seconds,
    :tlc5947_channel_lookup
  ]

  alias NervesBinaryClock.Utils

  @type digit_position :: :digit1 | :digit2 | :digit3 | :digit4

  @type display_type :: :common_anode | :common_cathode

  @type tlc5947_channel :: 0..23

  @type tlc5947_channel_lookup :: %{
          digit1: tlc5947_channel,
          digit2: tlc5947_channel,
          digit3: tlc5947_channel,
          digit4: tlc5947_channel,
          a: tlc5947_channel,
          b: tlc5947_channel,
          c: tlc5947_channel,
          d: tlc5947_channel,
          e: tlc5947_channel,
          f: tlc5947_channel,
          g: tlc5947_channel,
          p: tlc5947_channel
        }

  @type t :: %__MODULE__{
          display_type: boolean,
          seconds: 0..3599,
          tlc5947_channel_lookup: tlc5947_channel_lookup
        }

  @type p_flags :: {boolean, boolean, boolean, boolean}

  # Keys are list data structure, not tuple, because we want to iterate over them
  @pgfedcba_keys ~w(p g f e d c b a)a
  @digit_position_keys ~w(digit1 digit2 digit3 digit4)a

  # The tuple indices corresponds to number 0..9
  @pgfedcba_byte_lookup %{
    common_anode: {0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90},
    common_cathode: {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x4F}
  }

  @digit_position_bit_lookup %{
    {:common_anode, true} => 1,
    {:common_anode, false} => 0,
    {:common_cathode, true} => 0,
    {:common_cathode, false} => 1
  }

  @default_display_type :common_anode
  @default_tlc5947_channel_lookup %{
    a: 0,
    b: 1,
    c: 2,
    d: 3,
    e: 4,
    f: 5,
    g: 6,
    p: 7,
    digit1: 8,
    digit2: 9,
    digit3: 10,
    digit4: 11,
  }

  @doc """
  Takes an Elixir time and converts it to a list of bits for the presentation.
  """
  def to_leds(%{calendar: _, hour: _, minute: _, second: _, microsecond: _} = time, format_type, opts \\ []) do
    display_type = opts[:display_type] || @default_display_type
    tlc5947_channel_lookup = opts[:tlc5947_channel_lookup] || @default_tlc5947_channel_lookup

    seconds_since_zero_minute = Time.diff(time, %{time | minute: 0, second: 0})

    # Four lists of 24 bits
    number_to_bit_lookups(
      seconds_since_zero_minute,
      display_type,
      tlc5947_channel_lookup
    )
    |> Enum.map(fn bit_lookup ->
      Enum.map(0..23, fn ch ->
        bit_lookup[channel_key(ch)] || default_bit(display_type)
      end)
      |> Utils.formatter(format_type, opts)
    end)
  end

  def seconds_since_zero_minute(time) do
    Time.diff(time, %{time | minute: 0, second: 0})
  end

  @spec number_to_bit_lookups(0..9999, display_type, tlc5947_channel_lookup, p_flags) :: [any]
  def number_to_bit_lookups(
        four_digit_number,
        display_type,
        channel_lookup,
        p_flags \\ {false, false, false, false}
      )
      when is_integer(four_digit_number) and four_digit_number in 0..9999 do
    Integer.digits(four_digit_number, 10)
    |> Utils.zero_pad_list(4)
    |> Enum.with_index(fn one_digit_number, index ->
      common_map = digit_position_to_channel_bits(index, display_type, channel_lookup)

      one_digit_number
      |> one_digit_to_pgfedcba_bits(display_type, elem(p_flags, index))
      |> pgfedcba_bits_to_channel_bits(channel_lookup)
      |> Enum.into(common_map)
    end)
  end

  @spec digit_position_to_channel_bits(0..3, display_type, tlc5947_channel_lookup) ::
          %{atom => 0 | 1}
  def digit_position_to_channel_bits(digit_position, display_type, channel_lookup)
      when digit_position in 0..3 do
    Enum.map(@digit_position_keys, fn digit_position_key ->
      enabled = digit_position_key == digit_position_key(digit_position)
      channel_key = Map.fetch!(channel_lookup, digit_position_key) |> channel_key()
      digit_position_bit = Map.fetch!(@digit_position_bit_lookup, {display_type, enabled})

      {channel_key, digit_position_bit}
    end)
    |> Map.new()
  end

  @spec pgfedcba_bits_to_channel_bits([0 | 1], tlc5947_channel_lookup) :: %{atom => 0 | 1}
  def pgfedcba_bits_to_channel_bits(pgfedcba_bits, %{} = channel_lookup) do
    led_bits = Enum.zip(@pgfedcba_keys, pgfedcba_bits)

    Enum.map(@pgfedcba_keys, fn pgfedcba_key ->
      channel = Access.fetch!(channel_lookup, pgfedcba_key)
      led_bit = Access.fetch!(led_bits, pgfedcba_key)

      {channel_key(channel), led_bit}
    end)
    |> Map.new()
  end

  @spec one_digit_to_pgfedcba_bits(0..9, display_type, boolean) :: [0 | 1]
  def one_digit_to_pgfedcba_bits(number, display_type, with_p \\ false)
      when is_integer(number) and number in 0..9 do
    @pgfedcba_byte_lookup[display_type]
    |> elem(number)
    |> Utils.padded_bits(8)
    |> set_p(display_type, with_p)
  end

  defp set_p([_p | rest], :common_anode, true), do: [0 | rest]
  defp set_p([_p | rest], :common_anode, false), do: [1 | rest]
  defp set_p([_p | rest], :common_cathode, true), do: [1 | rest]
  defp set_p([_p | rest], :common_cathode, false), do: [0 | rest]

  defp default_bit(:common_anode), do: 0
  defp default_bit(:common_cathode), do: 1

  defp channel_key(ch) when is_integer(ch) and ch in 0..23, do: :"#{ch}"

  defp digit_position_key(0), do: :digit1
  defp digit_position_key(1), do: :digit2
  defp digit_position_key(2), do: :digit3
  defp digit_position_key(3), do: :digit4
end
