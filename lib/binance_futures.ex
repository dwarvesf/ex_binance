defmodule Dwarves.BinanceFutures do
  alias Binance.Rest.HTTPClient

  require Logger

  # Server

  @spec ping ::
          {:error,
           {:http_error, HTTPoison.Error.t()}
           | {:poison_decode_error, Poison.ParseError.t()}
           | map}
          | {:ok, false | nil | true | binary | list | number | map}
  @doc """
  Pings binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  def ping(is_testnet \\ false) do
    HTTPClient.get_binance("/fapi/v1/ping", [], is_testnet)
  end

  # Ticker

  @doc """
  Get all symbols and current prices listed in binance

  Returns `{:ok, [%Binance.SymbolPrice{}]}` or `{:error, reason}`.

  ## Example
  ```
  {:ok,
    [%Binance.SymbolPrice{price: "0.07579300", symbol: "ETHBTC"},
     %Binance.SymbolPrice{price: "0.01670200", symbol: "LTCBTC"},
     %Binance.SymbolPrice{price: "0.00114550", symbol: "BNBBTC"},
     %Binance.SymbolPrice{price: "0.00640000", symbol: "NEOBTC"},
     %Binance.SymbolPrice{price: "0.00030000", symbol: "123456"},
     %Binance.SymbolPrice{price: "0.04895000", symbol: "QTUMETH"},
     ...]}
  ```
  """
  def get_all_prices(is_testnet \\ false) do
    case HTTPClient.get_binance("/fapi/v1/ticker/price", [], is_testnet) do
      {:ok, data} ->
        {:ok, Enum.map(data, &Binance.SymbolPrice.new(&1))}

      err ->
        err
    end
  end

  # Order

  @doc """
  Creates a new order on binance

  Returns `{:ok, %{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://www.binance.com/restapipub.html#user-content-account-endpoints to understand all the parameters

  ## Examples
  ```
  create_order(
    %{"symbol" => "BTCUSDT", "quantity" => 1, "side" => "BUY", "type" => "MARKET"},
    "api_secret",
    "api_key",
    true)
  ```

  Result:
  ```
  {:ok,
   %{
     "orderId" => 809666629,
     "origQty" => "1",
     "origType" => "MARKET",
     "positionSide" => "BOTH",
     "price" => "0",
     "side" => "BUY",
     "status" => "NEW",
     "symbol" => "BTCUSDT",
     "type" => "MARKET",
     ...
   }
  }
  or
  {:error, {:binance_error, %{code: -2019, msg: "Margin is insufficient."}}}
  ```
  """
  def create_order(
        params,
        api_secret,
        api_key,
        is_testnet \\ false
      ) do
    arguments =
      params
      |> extract_order_params()
      |> Map.merge(%{
        recvWindow: get_receiving_window(params["receiving_window"]),
        timestamp: get_timestamp(params["timestamp"])
      })

    case HTTPClient.signed_request_binance(
           "/fapi/v1/order",
           arguments,
           :post,
           api_secret,
           api_key,
           is_testnet
         ) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
        |> parse_order_response
    end
  end

  def get_all_orders(api_key, secret_key, params, is_testnet \\ false) do
    binance_params = %{
      symbol: params["symbol"],
      orderId: params["orderId"],
      startTime: params["startTime"],
      endTime: params["endTime"],
      limit: params["limit"]
    }

    case HTTPClient.get_binance(
           "/fapi/v1/allOrders",
           binance_params,
           secret_key,
           api_key,
           is_testnet
         ) do
      {:error, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        parse_batch_orders_response(data)
    end
  end

  def get_open_orders(api_key, secret_key, is_testnet \\ false) do
    case HTTPClient.get_binance("/fapi/v1/openOrders", %{}, secret_key, api_key, is_testnet) do
      {:error, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        parse_batch_orders_response(data)
    end
  end

  @doc """
  get exchange info from binance

  Returns `{:ok, %{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binance-docs.github.io/apidocs/futures/en/#exchange-information to understand all the parameters

  ## Examples
  ```
  get_exchange_info(true)
  ```

  Result:
  ```
  {:ok,
   %{
      "timezone": "UTC",
      "serverTime": 1640141838081,
      "futuresType": "U_MARGINED",
      "symbols": [...],
      ...
   }
  }
  or
  {:error, {:binance_error, %{code: -2019, msg: "Margin is insufficient."}}}
  ```
  """
  def get_exchange_info(is_testnet \\ false) do
    case HTTPClient.get_binance("/fapi/v1/exchangeInfo", [], is_testnet) do
      {:error, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        parse_exchange_info(data)
    end
  end

  @doc """
  get account info from binance

  Returns `{:ok, %{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binance-docs.github.io/apidocs/futures/en/#account-information-v2-user_data to understand all the parameters

  ## Examples
  ```
  get_account_info("api_key", "api_secret", true)
  ```

  Result:
  ```
  {:ok,
   %{
      "timezone": "UTC",
      "serverTime": 1640141838081,
      "futuresType": "U_MARGINED",
      "symbols": [...],
      ...
   }
  }
  or
  {:error, {:binance_error, %{code: -2019, msg: "Margin is insufficient."}}}
  ```
  """
  def get_account_info(api_key, secret_key, is_testnet \\ false) do
    case HTTPClient.get_binance("/fapi/v2/account", %{}, secret_key, api_key, is_testnet) do
      {:error, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        parse_account_info(data)
    end
  end

  @doc """
  Creates a new **limit** **buy** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_limit_buy(
        %{"symbol" => symbol, "quantity" => quantity, "price" => price} = params,
        api_secret,
        api_key,
        is_testnet \\ false
      )
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    params
    |> Map.merge(%{"side" => "BUY", "type" => "LIMIT"})
    |> create_order(
      api_secret,
      api_key,
      is_testnet
    )
  end

  @doc """
  Creates a new **limit** **sell** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_limit_sell(
        %{"symbol" => symbol, "quantity" => quantity, "price" => price} = params,
        api_secret,
        api_key,
        is_testnet \\ false
      )
      when is_binary(symbol)
      when is_number(quantity)
      when is_number(price) do
    params
    |> Map.merge(%{"side" => "SELL", "type" => "LIMIT"})
    |> create_order(
      api_secret,
      api_key,
      is_testnet
    )
  end

  @doc """
  Creates a new **market** **buy** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_market_buy(
        %{"symbol" => symbol, "quantity" => quantity} = params,
        api_secret,
        api_key,
        is_testnet \\ false
      )
      when is_binary(symbol)
      when is_number(quantity) do
    params
    |> Map.merge(%{"side" => "BUY", "type" => "MARKET"})
    |> create_order(
      api_secret,
      api_key,
      is_testnet
    )
  end

  @doc """
  Creates a new **market** **sell** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_market_sell(
        %{"symbol" => symbol, "quantity" => quantity} = params,
        api_secret,
        api_key,
        is_testnet \\ false
      )
      when is_binary(symbol)
      when is_number(quantity) do
    params
    |> Map.merge(%{"side" => "SELL", "type" => "MARKET"})
    |> create_order(
      api_secret,
      api_key,
      is_testnet
    )
  end

  @doc """
  Creates a batch orders on binance.Max 5 orders

  Returns `{:ok, [%{order} or %{code: code, msg: msg}]}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binance-docs.github.io/apidocs/futures/en/#place-multiple-orders-trade to understand all the parameters

  ## Examples
  ```
  create_batch_orders(%{
      "batch_orders" => [
        %{"symbol" => "BTCUSDT", "quantity" => 1, "side" => "BUY", "type" => "MARKET"},
        %{"symbol" => "ETHUSDT", "quantity" => 1, "side" => "BUY", "type" => "MARKET"}
      ]
    },
    "api_secret",
    "api_key",
    true)
  ```

  Result:
  ```
  {:ok,
  [
   %{"code" => -2019, "msg" => "Margin is insufficient."},
   %{
     "orderId" => 809666629,
     "origQty" => "1",
     "origType" => "MARKET",
     "positionSide" => "BOTH",
     "price" => "0",
     "side" => "BUY",
     "status" => "NEW",
     "symbol" => "ETHUSDT",
     "type" => "MARKET",
     ...
   }
  ]}
  ```
  """
  def create_batch_orders(
        params,
        api_secret,
        api_key,
        is_testnet \\ false
      ) do
    orders =
      params["batch_orders"]
      |> Enum.map(fn order ->
        extract_order_params(order)
        |> stringify()
      end)
      |> Enum.join(", ")

    arguments = %{
      batchOrders: URI.encode_www_form("[#{orders}]"),
      recvWindow: get_receiving_window(params["receiving_window"]),
      timestamp: get_timestamp(params["timestamp"])
    }

    case HTTPClient.signed_request_binance(
           "/fapi/v1/batchOrders",
           arguments,
           :post,
           api_secret,
           api_key,
           is_testnet
         ) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        parse_batch_orders_response(data)
    end
  end

  @doc """
  Change initial leverage

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`

  ## Examples
  ```
  change_leverage(%{
    "symbol" => "BTCUSDT", "leverage" => 5},
    "api_secret",
    "api_key",
    true)
  ```

  Result: `{:ok, %{"leverage" => 5, "maxNotionalValue" => "50000000", "symbol" => "BTCUSDT"}}`
  """
  def change_leverage(
        %{"symbol" => symbol, "leverage" => leverage} = params,
        api_secret,
        api_key,
        is_testnet \\ false
      )
      when is_binary(symbol)
      # target initial leverage: int from 1 to 125
      when is_number(leverage) and leverage >= 1 and leverage <= 125 do
    arguments = %{
      symbol: symbol,
      leverage: leverage,
      recvWindow: get_receiving_window(params["receiving_window"]),
      timestamp: get_timestamp(params["timestamp"])
    }

    case HTTPClient.signed_request_binance(
           "/fapi/v1/leverage",
           arguments,
           :post,
           api_secret,
           api_key,
           is_testnet
         ) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  # Misc

  defp format_price(num) when is_float(num), do: :erlang.float_to_binary(num, [{:decimals, 8}])
  defp format_price(num) when is_integer(num), do: inspect(num)
  defp format_price(num) when is_binary(num), do: num

  @doc """
  Searches and normalizes the symbol as it is listed on binance.

  To retrieve this information, a request to the binance API is done. The result is then **cached** to ensure the request is done only once.

  Order of which symbol comes first, and case sensitivity does not matter.

  Returns `{:ok, "SYMBOL"}` if successfully, or `{:error, reason}` otherwise.

  ## Examples
  These 3 calls will result in the same result string:
  ```
  find_symbol(%Binance.TradePair{from: "ETH", to: "REQ"})
  ```
  ```
  find_symbol(%Binance.TradePair{from: "REQ", to: "ETH"})
  ```
  ```
  find_symbol(%Binance.TradePair{from: "rEq", to: "eTH"})
  ```

  Result: `{:ok, "REQETH"}`

  """
  def find_symbol(%Binance.TradePair{from: from, to: to} = tp)
      when is_binary(from)
      when is_binary(to) do
    case Binance.SymbolCache.get() do
      # cache hit
      {:ok, data} ->
        from = String.upcase(from)
        to = String.upcase(to)

        found = Enum.filter(data, &Enum.member?([from <> to, to <> from], &1))

        case Enum.count(found) do
          1 -> {:ok, found |> List.first()}
          0 -> {:error, :symbol_not_found}
        end

      # cache miss
      {:error, :not_initialized} ->
        case get_all_prices() do
          {:ok, price_data} ->
            price_data
            |> Enum.map(fn x -> x.symbol end)
            |> Binance.SymbolCache.store()

            find_symbol(tp)

          err ->
            err
        end

      err ->
        err
    end
  end

  defp extract_order_params(
         %{"symbol" => symbol, "side" => side, "type" => type, "quantity" => quantity} = params
       ) do
    %{
      symbol: symbol,
      side: side,
      type: type,
      quantity: quantity
    }
    |> Map.merge(
      unless(
        is_nil(params["new_client_order_id"]),
        do: %{newClientOrderId: params["new_client_order_id"]},
        else: %{}
      )
    )
    |> Map.merge(
      unless(is_nil(params["stop_price"]),
        do: %{stopPrice: format_price(params["stop_price"])},
        else: %{}
      )
    )
    |> Map.merge(
      unless(is_nil(params["iceberg_quantity"]),
        do: %{icebergQty: params["iceberg_quantity"]},
        else: %{}
      )
    )
    |> Map.merge(
      unless(is_nil(params["time_in_force"]),
        do: %{timeInForce: params["time_in_force"]},
        else: %{}
      )
    )
    |> Map.merge(
      unless(is_nil(params["price"]), do: %{price: format_price(params["price"])}, else: %{})
    )
  end

  defp stringify(map = %{}) do
    kvString =
      map
      |> Map.to_list()
      |> Enum.map(fn x ->
        Tuple.to_list(x) |> Enum.map(&"\"#{&1}\"") |> Enum.join(":")
      end)
      |> Enum.join(",")

    "{#{kvString}}"
  end

  def parse_exchange_info({:ok, response}) do
    exchange_info =
      response
      |> Binance.ExchangeInfo.new()

    symbols =
      exchange_info.symbols
      |> Enum.map(fn itm ->
        itm |> Binance.Symbol.new()
      end)

    assets =
      exchange_info.assets
      |> Enum.map(fn itm ->
        itm |> Binance.SymbolAsset.new()
      end)

    rate_limits =
      exchange_info.rate_limits
      |> Enum.map(fn itm ->
        itm |> Binance.SymbolRateLimit.new()
      end)

    exchange_info =
      exchange_info
      |> Map.put(:symbols, symbols)
      |> Map.put(:assets, assets)
      |> Map.put(:rate_limits, rate_limits)

    {:ok, exchange_info}
  end

  def parse_exchange_info({
        :error,
        {
          :binance_error,
          %{code: -2010, msg: _msg} = reason
        }
      }) do
    {:error, %Binance.InsufficientBalanceError{reason: reason}}
  end

  def parse_account_info({:ok, response}) do
    account_info =
      response
      |> Binance.Account.new()

    assets =
      account_info.assets
      |> Enum.map(fn itm ->
        itm |> Binance.AccountAsset.new()
      end)

    positions =
      account_info.positions
      |> Enum.map(fn itm ->
        itm |> Binance.AccountPosition.new()
      end)

    account_info =
      account_info
      |> Map.put(:assets, assets)
      |> Map.put(:positions, positions)

    {:ok, account_info}
  end

  def parse_account_info({
        :error,
        {
          :binance_error,
          %{code: -2010, msg: _msg} = reason
        }
      }) do
    {:error, %Binance.InsufficientBalanceError{reason: reason}}
  end

  def parse_order_response({:ok, response}) do
    {:ok, Binance.OrderResponse.new(response)}
  end

  def parse_order_response({
        :error,
        {
          :binance_error,
          %{code: -2010, msg: "Account has insufficient balance for requested action."} = reason
        }
      }) do
    {:error, %Binance.InsufficientBalanceError{reason: reason}}
  end

  def parse_batch_orders_response({
        :ok,
        responses
      }) do
    {:ok,
     Enum.map(responses, fn res ->
       case res do
         %{"code" => code, "msg" => msg} -> %{"code" => code, "msg" => msg}
         _ -> Binance.OrderResponse.new(res)
       end
     end)}
  end

  defp get_timestamp(timestamp) do
    case timestamp do
      # timestamp needs to be in milliseconds
      nil ->
        :os.system_time(:millisecond)

      val ->
        val
    end
  end

  defp get_receiving_window(receiving_window) do
    case receiving_window do
      nil ->
        1000

      val ->
        val
    end
  end
end
