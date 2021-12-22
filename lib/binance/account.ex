defmodule Binance.Account do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/account

  ```
  defstruct [
    :fee_tier,
    :can_trade,
    :can_deposit,
    :can_withdraw,
    :update_time,
    :total_initial_margin,
    :total_maint_margin,
    :total_wallet_balance,
    :total_unrealized_profit,
    :total_margin_balance,
    :total_position_initial_margin,
    :total_open_order_initial_margin,
    :total_cross_wallet_balance,
    :total_cross_un_pnl,
    :available_balance,
    :max_withdraw_amount,
    :assets,
    :positions
  ]
  ```
  """

  defstruct [
    :fee_tier,
    :can_trade,
    :can_deposit,
    :can_withdraw,
    :update_time,
    :total_initial_margin,
    :total_maint_margin,
    :total_wallet_balance,
    :total_unrealized_profit,
    :total_margin_balance,
    :total_position_initial_margin,
    :total_open_order_initial_margin,
    :total_cross_wallet_balance,
    :total_cross_un_pnl,
    :available_balance,
    :max_withdraw_amount,
    :assets,
    :positions
  ]

  use ExConstructor
end
