defmodule Binance.OrderResponse do
  defstruct [
    :avg_price,
    :client_order_id,
    :executed_qty,
    :order_id,
    :orig_qty,
    :price,
    :side,
    :status,
    :symbol,
    :time_in_force,
    :time,
    :type,
    :close_position,
    :cum_quote,
    :orig_type,
    :position_side,
    :price_protect,
    :reduce_only,
    :stop_price,
    :working_type,
    :update_time
  ]

  use ExConstructor
end
