defmodule NervesBinaryClock.FourDigitSevenSegmentClock.ClockTimeTest do
  use ExUnit.Case
  alias NervesBinaryClock.FourDigitSevenSegmentClock
  import NervesBinaryClock.FourDigitSevenSegmentClock.ClockTime

  @tlc5947_channel_lookup %{
    digit1: 12,
    digit2: 13,
    digit3: 14,
    digit4: 15,
    a: 16,
    b: 17,
    c: 18,
    d: 19,
    e: 20,
    f: 21,
    g: 22,
    p: 23
  }

  @default_opts [tlc5947_channel_lookup: @tlc5947_channel_lookup]

  test "Constructor calculates seconds since zero minute" do
    time1 = FourDigitSevenSegmentClock.ClockTime.new(~N[2022-02-21 01:29:59], @default_opts)
    assert time1.seconds_since_zero_minute == 1799

    time2 = FourDigitSevenSegmentClock.ClockTime.new(~N[2022-02-21 02:29:59], @default_opts)
    assert time2.seconds_since_zero_minute == 1799

    time3 = FourDigitSevenSegmentClock.ClockTime.new(~N[2022-02-21 03:59:59], @default_opts)
    assert time3.seconds_since_zero_minute == 3599
  end

  test "Translate one-digit number to seven segment code without decimal point" do
    assert one_digit_to_pgfedcba_bits(3, :common_anode) == [1, 0, 1, 1, 0, 0, 0, 0]
    assert one_digit_to_pgfedcba_bits(3, :common_cathode) == [0, 1, 0, 0, 1, 1, 1, 1]
  end

  test "Translate one-digit number to seven segment code with decimal point" do
    assert one_digit_to_pgfedcba_bits(3, :common_anode, true) == [0, 0, 1, 1, 0, 0, 0, 0]
    assert one_digit_to_pgfedcba_bits(3, :common_cathode, true) == [1, 1, 0, 0, 1, 1, 1, 1]
  end

  test "PGFEDCBA bits to TLC5947 channel bits" do
    pgfedcba_3 = [1, 0, 1, 1, 0, 0, 0, 0]

    assert pgfedcba_bits_to_channel_bits(pgfedcba_3, @tlc5947_channel_lookup) ==
             %{"16": 0, "17": 0, "18": 0, "19": 0, "20": 1, "21": 1, "22": 0, "23": 1}

    assert_raise KeyError, ~r/^key :a not found/, fn ->
      invalid_channel_lookup = Map.drop(@tlc5947_channel_lookup, [:a])
      pgfedcba_bits_to_channel_bits(pgfedcba_3, invalid_channel_lookup)
    end
  end

  test "Translate display position to channel bits" do
    assert digit_position_to_channel_bits(0, :common_anode, @tlc5947_channel_lookup) ==
             %{"12": 1, "13": 0, "14": 0, "15": 0}

    assert digit_position_to_channel_bits(2, :common_anode, @tlc5947_channel_lookup) ==
             %{"12": 0, "13": 0, "14": 1, "15": 0}

    assert digit_position_to_channel_bits(2, :common_cathode, @tlc5947_channel_lookup) ==
             %{"12": 1, "13": 1, "14": 0, "15": 1}
  end

  test "Translate four-digit number to TLC5947 bits" do
    tlc5947_bits = number_to_bit_lookups(234, :common_anode, @tlc5947_channel_lookup)

    {expected, _} =
      Code.eval_string("""
      [
        %{"12": 1, "13": 0, "14": 0, "15": 0, "16": 0, "17": 0, "18": 0, "19": 0, "20": 0, "21": 0, "22": 1, "23": 1},
        %{"12": 0, "13": 1, "14": 0, "15": 0, "16": 0, "17": 0, "18": 1, "19": 0, "20": 0, "21": 1, "22": 0, "23": 1},
        %{"12": 0, "13": 0, "14": 1, "15": 0, "16": 0, "17": 0, "18": 0, "19": 0, "20": 1, "21": 1, "22": 0, "23": 1},
        %{"12": 0, "13": 0, "14": 0, "15": 1, "16": 1, "17": 0, "18": 0, "19": 1, "20": 1, "21": 0, "22": 0, "23": 1}
      ]
      """)

    assert tlc5947_bits == expected
  end

  test "Translate four-digit number to a list of four TLC5947 datasets" do
    time1 = FourDigitSevenSegmentClock.ClockTime.new(~N[2022-02-21 01:29:59], @default_opts)

    {expected, _} =
      Code.eval_string("""
      [
        <<6, 0, 96, 6, 0, 96, 6, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        <<6, 0, 96, 6, 0, 96, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        <<6, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        <<6, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      ]
      """)

    assert to_leds(time1, :bytes) == expected
  end
end
