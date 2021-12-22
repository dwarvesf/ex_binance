defmodule Binance.SymbolRateLimit do
  @moduledoc """
  Struct for representing the result returned by /api/v3/openOrders
  """

  defstruct [
    :rate_limit_type,
    :interval,
    :interval_num,
    :limit
  ]

  use ExConstructor
end
