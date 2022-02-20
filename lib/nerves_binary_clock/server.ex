defmodule NervesBinaryClock.Server do
  @moduledoc """
  The service layer that processes periodic requests for time and delegates the task of showing the
  local time to configurable adapter layers.
  """

  use GenServer

  defstruct [:binary_clock, :brightness]

  @default_brightness 0x060

  @type binary_clock_mod ::
          NervesBinaryClock.BinaryClock.Dev
          | NervesBinaryClock.BinaryClock.Target
          | NervesBinaryClock.BinaryClock.Test

  @type option ::
          {:spi_bus_name, String.t()}
          | {:binary_clock_mod, binary_clock_mod}
          | {:brightness, 0x000..0xFFF}

  @spec start_link([option]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec brightness :: 0x000..0xFFF
  def brightness(), do: GenServer.call(__MODULE__, :brightness)

  @spec set_brightness(0x000..0xFFF) :: :ok
  def set_brightness(value), do: GenServer.cast(__MODULE__, {:set_brightness, value})

  @impl true
  def init(opts) do
    bus_name = opts[:spi_bus_name]
    binary_clock_mod = opts[:binary_clock_mod] || NervesBinaryClock.BinaryClock.Dev
    brightness = opts[:brightness] || @default_brightness

    binary_clock = init_binary_clock(binary_clock_mod, bus_name)

    state = %__MODULE__{
      binary_clock: binary_clock,
      brightness: brightness
    }

    {:ok, state}
  end

  @impl true
  def handle_info(:tick_binary_clock, state) do
    binary_clock = advance_binary_clock(state.binary_clock, state.brightness)

    {:noreply, %{state | binary_clock: binary_clock}}
  end

  @impl true
  def handle_cast({:set_brightness, value}, state) do
    {:noreply, %{state | brightness: value}}
  end

  @impl true
  def handle_call(:brightness, _from, state) do
    {:reply, state.brightness, state}
  end

  defp init_binary_clock(binary_clock_mod, bus_name) do
    binary_clock = binary_clock_mod.new(bus_name) |> NervesBinaryClock.BinaryClock.open()
    %{__struct__: ^binary_clock_mod} = binary_clock
  end

  defp advance_binary_clock(binary_clock, brightness) do
    NervesBinaryClock.BinaryClock.show(binary_clock, local_time(), brightness: brightness)
  end

  defp local_time() do
    NaiveDateTime.local_now()
  end
end
