defmodule Binance.AccountPosition do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/account

  ```
  defstruct [
    :maker_commission,
    :taker_commission,
    :buyer_commission,
    :seller_commission,
    :can_trade,
    :can_withdrawl,
    :can_deposit,
    :update_time,
    :balances
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
