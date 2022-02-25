defmodule NervesBinaryClock.BinaryClockTest do
  use ExUnit.Case
  alias NervesBinaryClock.Clockwork
  alias NervesBinaryClock.BinaryClock

  test "Tracks time" do
    adapter =
      BinaryClock.Test.new()
      |> Clockwork.open()
      |> Clockwork.show(time: ~T[01:02:04.0])
      |> Clockwork.show(time: ~T[01:02:05.0])

    [second, first] = adapter.bits

    assert [0, 0, 1 | _rest] = first
    assert [1, 0, 1, 0, 0, 0, 1 | _rest] = second
  end
end
