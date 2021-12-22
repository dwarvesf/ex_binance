defmodule Binance.SymbolAsset do
  @moduledoc """
  Struct for representing the result returned by /api/v3/openOrders
  """

  defstruct [
    :asset,
    :margin_available,
    :auto_asset_exchange
  ]

  use ExConstructor
end
