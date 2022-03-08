defmodule Dwarves.BinanceSpot do
  alias Binance.Rest.HTTPClient

  @endpoint Application.get_env(
              :dwarves_binancex,
              :spot_url,
              "https://api.binance.com"
            )
  @testnet_endpoint Application.get_env(
                      :dwarves_binancex,
                      :spot_testnet_url,
                      "https://testnet.binance.vision"
                    )

  require Logger

  def get_endpoint(is_testnet) do
    case is_testnet do
      true -> @testnet_endpoint
      false -> @endpoint
    end
  end

  # Server

  @doc """
  Pings binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  def ping(is_testnet \\ false) do
    endpoint = get_endpoint(is_testnet)
    HTTPClient.get_binance("#{endpoint}/sapi/v1/ping", [])
  end

  # Wallet
  @doc """
  Get Daily Account Snapshot.

  Returns `{:ok, %{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binance-docs.github.io/apidocs/spot/en/#daily-account-snapshot-user_data to understand all the parameters

  ## Examples
  ```
  account_snapshot(%{"type" => "FUTURES", "start_time" => 1642032000000, "end_time" => 1642032000000}, "api_key", "api_secret")
  ```

  Result:
  ```
  {:ok,
   %{
      code: 200,
      msg: "",
      snapshotVos: [...]
    }
  or
  {:error, {:binance_error, %{
        code: -3026,
        msg: "request param 'type' wrong, shoud be in ('SPOT', 'MARGIN', 'FUTURES')"
      }
    }
  }
  ```
  """
  def account_snapshot(
        %{"type" => type} = params,
        api_key,
        api_secret,
        is_testnet \\ false
      ) do
    arguments =
      %{
        type: type,
        recvWindow: get_receiving_window(params["receiving_window"]),
        timestamp: get_timestamp(params["timestamp"])
      }
      |> Map.merge(
        unless(
          is_nil(params["start_time"]),
          do: %{startTime: params["start_time"]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params["end_time"]),
          do: %{endTime: params["end_time"]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params["limit"]),
          do: %{limit: params["limit"]},
          else: %{}
        )
      )

    endpoint = get_endpoint(is_testnet)

    case HTTPClient.get_binance(
           "#{endpoint}/sapi/v1/accountSnapshot",
           arguments,
           api_secret,
           api_key
         ) do
      {:error, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  # Corporate (sub-account)
  @doc """
  Universal Transfer (For Master Account).

  Returns `{:ok, %{}}` or `{:error, reason}`.

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binance-docs.github.io/apidocs/spot/en/#universal-transfer-for-master-account to understand all the parameters

  ## Examples
  ```
  universal_transfer(%{"from_email" => "email@gmail.com", "to_email" => "email@gmail.com", "from_account_type" => "USDT_FUTURE", "to_account_type" => "SPOT", "asset" => "USDT", "amount" => 100},"api_key",  "secret_key")
  ```

  Result:
  ```
  {:ok,
   %{
      tranId: "tranId"
    }
  or
  {:error, {:binance_error, %{
        code: -1000,
        msg: "No enum constant com.binance.accountsubuser.enums.TranferWay.FUTURE_TO_FUTURE"
      }
    }
  }
  ```
  """
  def universal_transfer(
        %{
          "from_account_type" => from_account_type,
          "to_account_type" => to_account_type,
          "asset" => asset,
          "amount" => amount
        } = params,
        api_key,
        api_secret
      ) do
    arguments =
      %{
        fromAccountType: from_account_type,
        toAccountType: to_account_type,
        asset: asset,
        amount: amount,
        recvWindow: get_receiving_window(params["receiving_window"]),
        timestamp: get_timestamp(params["timestamp"])
      }
      |> Map.merge(
        unless(
          is_nil(params["from_email"]),
          do: %{fromEmail: params["from_email"]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params["to_email"]),
          do: %{toEmail: params["to_email"]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params["client_tran_id"]),
          do: %{clientTranId: params["client_tran_id"]},
          else: %{}
        )
      )

    endpoint = get_endpoint(false)

    case HTTPClient.signed_request_binance(
           "#{endpoint}/sapi/v1/sub-account/universalTransfer",
           arguments,
           :post,
           api_secret,
           api_key
         ) do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      data ->
        data
    end
  end

  # Misc

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
        5000

      val ->
        val
    end
  end
end
