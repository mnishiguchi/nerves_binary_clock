defmodule NervesBinaryClock.BinaryClock.Target do
  @moduledoc """
  This adapter physically opens the bus and sends the bytes representing the clock face.

  ## Examples

      BinaryClock.Target.new
      |> BinaryClock.open
      |> BinaryClock.show(~T[13:35:35.926971])

  """

  defstruct [:bus_name, :spi, :time]

  def new(bus_name) do
    %__MODULE__{bus_name: bus_name}
  end

  defimpl NervesBinaryClock.BinaryClock do
    @impl true
    def open(%{bus_name: bus_name} = adapter) do
      # The service layer will respond to this message.
      :timer.send_interval(1_000, :tick_binary_clock)

      bus_name = bus_name || hd(Circuits.SPI.bus_names())
      {:ok, spi} = Circuits.SPI.open(bus_name)

      %{adapter | spi: spi}
    end

    @impl true
    def show(adapter, time, opts \\ []) do
      brightness = opts[:brightness]

      adapter
      |> struct!(time: time)
      |> transfer(brightness)
    end

    defp transfer(adapter, brightness) do
      bytes =
        adapter.time
        |> NervesBinaryClock.BinaryTime.new()
        |> NervesBinaryClock.BinaryTime.to_leds(:bytes, brightness: brightness)

      {:ok, _} = Circuits.SPI.transfer(adapter.spi, bytes)

      adapter
    end
  end
end
