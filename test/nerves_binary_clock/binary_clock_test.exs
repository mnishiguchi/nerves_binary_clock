defmodule NervesBinaryClock.BinaryClockTest do
  use ExUnit.Case
  alias NervesBinaryClock.BinaryClock

  test "Tracks time" do
    adapter =
      BinaryClock.Test.new()
      |> BinaryClock.open()
      |> BinaryClock.show(~T[01:02:04.0])
      |> BinaryClock.show(~T[01:02:05.0])

    [second, first] = adapter.bits

    assert [0, 0, 1 | _rest] = first
    assert [1, 0, 1, 0, 0, 0, 1 | _rest] = second
  end
end
