defmodule Binance.SpotBalance do
  @moduledoc """
  Struct for representing a result row as returned by /api/v3/account

  ```
  defstruct [
    :asset,
    :free,
    :locked
  ]
  ```
  """

  defstruct [
    :asset,
    :free,
    :locked
  ]

  use ExConstructor
end
