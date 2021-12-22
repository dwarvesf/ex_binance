defmodule Binance.SymbolFilter do
  @moduledoc """
  Struct for representing the result returned by /api/v3/openOrders
  ```
  defstruct [
    :min_price,
    :max_price,
    :filter_type,
    :tick_size
  ]
  ```
  """

  defstruct [
    :min_price,
    :max_price,
    :filter_type,
    :tick_size
  ]

  use ExConstructor
end
