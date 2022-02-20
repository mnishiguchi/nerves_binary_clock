defmodule NervesBinaryClock.Server do
  @moduledoc """
  The service layer that processes periodic requests for time and delegates the task of showing the
  local time to configurable adapter layers.
  """

  use GenServer

  @default_spi_bus_name "spidev0.0"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    bus_name = opts[:spi_bus_name] || @default_spi_bus_name
    binary_clock_mod = opts[:binary_clock_mod] || NervesBinaryClock.BinaryClock.Dev

    binary_clock = init_binary_clock(binary_clock_mod, bus_name)

    {:ok, binary_clock}
  end

  @impl true
  def handle_info(:tick_binary_clock, binary_clock) do
    {:noreply, advence_binary_clock(binary_clock)}
  end

  defp init_binary_clock(binary_clock_mod, bus_name) do
    %{__struct__: ^binary_clock_mod} =
      binary_clock_mod.new(bus_name)
      |> NervesBinaryClock.BinaryClock.open()
  end

  defp advence_binary_clock(binary_clock) do
    NervesBinaryClock.BinaryClock.show(binary_clock, local_time())
  end

  defp local_time() do
    NaiveDateTime.local_now()
  end
end
