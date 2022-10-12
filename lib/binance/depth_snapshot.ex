defmodule Binance.DepthSnapshot do
  @moduledoc """
  Struct for representing result returned by /fapi/v1/depth

  ```
  defstruct [
    :lastUpdateId,
    :E,             # event time
    :T,             # transaction time
    :bids,
    :asks,
  ]
  ```
  """

  defstruct [
    :lastUpdateId,
    :E,
    :T,
    :bids,
    :asks
  ]

  use ExConstructor
end
