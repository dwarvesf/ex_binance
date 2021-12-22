defmodule Binance.AccountAsset do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/account

  ```
  defstruct [
    :asset,
    :wallet_balance,
    :unrealized_profit,
    :margin_balance,
    :maint_margin,
    :initial_margin,
    :position_initial_margin,
    :open_order_initial_margin,
    :cross_wallet_balance,
    :cross_un_pnl,
    :available_balance,
    :max_withdraw_amount,
    :margin_available,
    :update_time
  ]
  ```
  """

  defstruct [
    :symbol,
    :initial_margin,
    :maint_margin,
    :unrealized_profit,
    :position_initial_margin,
    :open_order_initial_margin,
    :leverage,
    :isolated,
    :entry_price,
    :max_notional,
    :bid_notional,
    :ask_notional,
    :position_side,
    :position_amt,
    :update_time
  ]

  use ExConstructor
end
