defmodule Binance.SwapHistory do
  @moduledoc """
  Struct for representing the result returned by /sapi/v1/bswap/swap
  """

  defstruct [
    :swap_id,
    :swap_time,
    :status,
    :quote_asset,
    :base_asset,
    :quote_qty,
    :base_qty,
    :price,
    :fee
  ]

  use ExConstructor
end
