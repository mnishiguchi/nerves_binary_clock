defmodule NervesBinaryClock.BinaryClock.Target do
  @moduledoc """
  The `NervesBinaryClock.BinaryClock.Target` adapter physically opens the bus and sends the bytes
  representing the clock face.
  """

  @behaviour NervesBinaryClock.BinaryClock

  defstruct [:time, :spi]

  @impl true
  def open(bus_name) do
    # The service layer will respond to this message.
    :timer.send_interval(1_000, :tick_binary_clock)

    bus_name = bus_name || hd(Circuits.SPI.bus_names())
    {:ok, spi} = Circuits.SPI.open(bus_name)

    %__MODULE__{spi: spi}
  end

  @impl true
  def show(adapter, time) do
    adapter
    |> struct!(time: time)
    |> transfer()
  end

  defp transfer(adapter) do
    bytes =
      adapter.time
      |> NervesBinaryClock.BinaryTime.new()
      |> NervesBinaryClock.BinaryTime.to_leds(:bytes)

    {:ok, _} = Circuits.SPI.transfer(adapter.spi, bytes)

    adapter
  end
end
