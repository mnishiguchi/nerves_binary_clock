defprotocol HelloNervesClock.Clockwork do
  @moduledoc """
  A contract for interacting with the clock hardware. Each adapter
  implementation will handle a different use case.
  """

  @type time :: %{
          required(:hour) => non_neg_integer(),
          required(:minute) => non_neg_integer(),
          required(:second) => non_neg_integer(),
          optional(atom()) => any()
        }

  @doc "Initializes an adapter."
  @spec open(struct) :: struct
  def open(adapter)

  @doc "Shows the provided time somehow."
  @spec show(struct, keyword) :: struct
  def show(adapter, opts \\ [])

  @doc "Closes an adapter."
  @spec close(struct) :: :ok
  def close(adapter)
end
