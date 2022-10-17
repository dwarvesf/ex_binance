defmodule Binance.SpotAccount do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/account

  ```
  defstruct [
    :maker_commission,
    :taker_commission,
    :buyer_commission,
    :seller_commission,
    :can_trade,
    :can_withdraw,
    :can_deposit,
    :brokered,
    :update_time,
    :account_type,
    :balances,
    :permissions
  ]
  ```
  """

  defstruct [
    :maker_commission,
    :taker_commission,
    :buyer_commission,
    :seller_commission,
    :can_trade,
    :can_withdraw,
    :can_deposit,
    :brokered,
    :update_time,
    :account_type,
    :balances,
    :permissions
  ]

  use ExConstructor
end
