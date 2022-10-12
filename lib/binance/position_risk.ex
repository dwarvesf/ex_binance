defmodule Binance.PositionRisk do
  @moduledoc """
  Struct for representing result returned by /fapi/v2/positionRisk

  ```
  defstruct [
    :entryPrice,
    :marginType,
    :isAutoAddMargin,
    :isolatedMargin,
    :leverage,
    :liquidationPrice,
    :markPrice,
    :maxNotionalValue,
    :positionAmt,
    :notional,
    :isolatedWallet,
    :symbol,
    :unRealizedProfit,
    :positionSide,
    :updateTime
  ]
  ```
  """

  defstruct [
    :entryPrice,
    :marginType,
    :isAutoAddMargin,
    :isolatedMargin,
    :leverage,
    :liquidationPrice,
    :markPrice,
    :maxNotionalValue,
    :positionAmt,
    :notional,
    :isolatedWallet,
    :symbol,
    :unRealizedProfit,
    :positionSide,
    :updateTime
  ]

  use ExConstructor
end
