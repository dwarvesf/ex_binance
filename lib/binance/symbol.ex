defmodule Binance.Symbol do
  @moduledoc """
  Struct for representing the result returned by /api/v3/openOrders
  """

  defstruct [
    :symbol,
    :pair,
    :contract_type,
    :delivery_date,
    :onboard_date,
    :status,
    :maint_margin_percent,
    :required_margin_percent,
    :base_asset,
    :quote_asset,
    :margin_asset,
    :price_precision,
    :quantity_precision,
    :base_asset_precision,
    :quote_precision,
    :underlying_type,
    :underlying_sub_type,
    :settle_plan,
    :trigger_protect,
    :liquidation_fee,
    :market_take_bound,
    :filters,
    :order_types,
    :time_in_force
  ]

  use ExConstructor
end
