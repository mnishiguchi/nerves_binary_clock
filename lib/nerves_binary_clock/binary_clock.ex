defmodule NervesBinaryClock.BinaryClock do
  @moduledoc """
  A contract for interacting with the binary clock hardware. Each adapter implementation will
  handle a different use case.
  """

  @type bus_name :: String.t()
  @type adapter :: any

  @doc "Initializes an adapter."
  @callback open(bus_name) :: adapter

  @doc "Converts the adapter to a visual representation."
  @callback show(adapter, Time.t()) :: adapter
end
