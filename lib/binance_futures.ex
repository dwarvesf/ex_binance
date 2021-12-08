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
    HTTPClient.get_binance("/fapi/v1/ping", is_testnet)
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
    case HTTPClient.get_binance("/fapi/v1/ticker/price", is_testnet) do
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
  """
  def create_order(
        %{"symbol" => symbol, "side" => side, "type" => type, "quantity" => quantity} = params,
        api_secret,
        api_key,
        is_testnet \\ false
      ) do
    timestamp =
      case params["timestamp"] do
        # timestamp needs to be in milliseconds
        nil ->
          :os.system_time(:millisecond)

        t ->
          t
      end

    receiving_window =
      case params["receiving_window"] do
        nil ->
          1000

        t ->
          t
      end

    arguments =
      %{
        symbol: symbol,
        side: side,
        type: type,
        quantity: quantity,
        recvWindow: receiving_window,
        timestamp: timestamp
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
        unless(is_nil(params["new_client_order_id"]),
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
    |> parse_order_response
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
    |> parse_order_response
  end

  @doc """
  Creates a new **market** **buy** order

  Symbol can be a binance symbol in the form of `"ETHBTC"` or `%Binance.TradePair{}`.

  Returns `{:ok, %{}}` or `{:error, reason}`
  """
  def order_market_buy(%Binance.TradePair{from: from, to: to} = symbol, quantity)
      when is_number(quantity)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_market_buy(binance_symbol, quantity)
      e -> e
    end
  end

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
  def order_market_sell(%Binance.TradePair{from: from, to: to} = symbol, quantity)
      when is_number(quantity)
      when is_binary(from)
      when is_binary(to) do
    case find_symbol(symbol) do
      {:ok, binance_symbol} -> order_market_sell(binance_symbol, quantity)
      e -> e
    end
  end

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

  defp parse_order_response({:ok, response}) do
    {:ok, Binance.OrderResponse.new(response)}
  end

  defp parse_order_response({
         :error,
         {
           :binance_error,
           %{code: -2010, msg: "Account has insufficient balance for requested action."} = reason
         }
       }) do
    {:error, %Binance.InsufficientBalanceError{reason: reason}}
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
end
