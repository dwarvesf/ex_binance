defmodule Binance.Ticker do
  @moduledoc """
  Struct for representing a result row as returned by /api/v1/ticker/24hr

  ```
  defstruct [
    :symbol,
    :price_change,
    :price_change_percent,
    :weighted_avg_price,
    :last_price,
    :lastQty,
    :openPrice,
    :highPrice,
    :lowPrice,
    :volume,
    :quoteVolume,
    :open_time,
    :close_time,
    :first_id,
    :last_id,
    :count
  ]
  ```
  """

  defstruct [
    :symbol,
    :price_change,
    :price_change_percent,
    :weighted_avg_price,
    :last_price,
    :lastQty,
    :openPrice,
    :highPrice,
    :lowPrice,
    :volume,
    :quoteVolume,
    :open_time,
    :close_time,
    :first_id,
    :last_id,
    :count
  ]

  use ExConstructor
end
