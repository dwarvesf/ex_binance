defmodule Binance.SwapQuote do
  @moduledoc """
  Struct for representing the result returned by /sapi/v1/bswap/swap
  """

  defstruct [
    :quote_asset,
    :base_asset,
    :quote_qty,
    :base_qty,
    :price,
    :slippage,
    :fee
  ]

  use ExConstructor
end
