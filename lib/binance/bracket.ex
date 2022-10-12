defmodule Binance.Bracket do
  @moduledoc """
  Struct for representing result returned by /fapi/v1/leverageBrackets

  ```
  defstruct [
    :bracket,
    :initialLeverage,
    :notionalCap,
    :notionalFloor,
    :maintMarginRatio,
    :cum
  ]
  ```
  """

  defstruct [
    :bracket,
    :initialLeverage,
    :notionalCap,
    :notionalFloor,
    :maintMarginRatio,
    :cum
  ]

  use ExConstructor
end
