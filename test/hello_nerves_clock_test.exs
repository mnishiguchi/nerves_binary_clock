defmodule HelloNervesClockTest do
  use ExUnit.Case
  doctest HelloNervesClock

  test "greets the world" do
    assert HelloNervesClock.hello() == :world
  end
end
