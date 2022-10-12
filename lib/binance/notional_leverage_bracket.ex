defmodule Binance.NotionalLeverageBracket do
  @moduledoc """
  Struct for representing result returned by /api/v1/leverageBrackets

  ```
  defstruct [
    :symbol,
    :brackets
  ]
  ```
  """

  defstruct [
    :symbol,
    :brackets
  ]

  use ExConstructor
end
