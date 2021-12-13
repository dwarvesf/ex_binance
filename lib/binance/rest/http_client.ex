defmodule Binance.Rest.HTTPClient do
  @endpoint Application.get_env(:dwarves_binancex, :end_point, "https://fapi.binance.com")
  @testnet_endpoint Application.get_env(
                      :dwarves_binancex,
                      :testnet_end_point,
                      "https://testnet.binancefuture.com"
                    )

  require Logger

  def get_endpoint(is_testnet) do
    case is_testnet do
      true -> @testnet_endpoint
      false -> @endpoint
    end
  end

  def get_binance(url, headers \\ [], is_testnet \\ false) do
    endpoint = get_endpoint(is_testnet)

    HTTPoison.get("#{endpoint}#{url}", headers)
    |> parse_response
  end

  def delete_binance(url, headers \\ [], is_testnet \\ false) do
    endpoint = get_endpoint(is_testnet)

    HTTPoison.delete("#{endpoint}#{url}", headers)
    |> parse_response
  end

  def get_binance(url, params, secret_key, api_key) do
    case prepare_request(url, params, secret_key, api_key) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        get_binance(url, headers)
    end
  end

  def delete_binance(url, params, secret_key, api_key) do
    case prepare_request(url, params, secret_key, api_key) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        delete_binance(url, headers)
    end
  end

  defp prepare_request(url, params, secret_key, api_key) do
    case validate_credentials(secret_key, api_key) do
      {:error, _} = error ->
        error

      _ ->
        headers = [{"X-MBX-APIKEY", api_key}]
        receive_window = 5000
        ts = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

        params =
          Map.merge(params, %{
            timestamp: ts,
            recvWindow: receive_window
          })

        argument_string = URI.encode_query(params)

        signature =
          generate_signature(
            :sha256,
            secret_key,
            argument_string
          )
          |> Base.encode16()

        {:ok, "#{url}?#{argument_string}&signature=#{signature}", headers}
    end
  end

  def signed_request_binance(url, params, method, api_secret, api_key, is_testnet \\ false) do
    argument_string =
      params
      |> prepare_query_params()

    # generate signature
    signature =
      generate_signature(
        :sha256,
        api_secret,
        argument_string
      )
      |> Base.encode16()

    body = "#{argument_string}&signature=#{signature}"

    endpoint = get_endpoint(is_testnet)

    case apply(HTTPoison, method, [
           "#{endpoint}#{url}",
           body,
           [
             {"X-MBX-APIKEY", api_key},
             {"Content-type", "application/x-www-form-urlencoded"}
           ]
         ]) do
      {:error, err} ->
        {:error, {:http_error, err}}

      {:ok, response} ->
        case Poison.decode(response.body) do
          {:ok, data} -> {:ok, data}
          {:error, err} -> {:error, {:poison_decode_error, err}}
        end
    end
  end

  @doc """
  You need to send an empty body and the api key
  to be able to create a new listening key.

  """
  def unsigned_request_binance(url, data, method, is_testnet \\ false) do
    headers = [
      {"X-MBX-APIKEY", Application.get_env(:binance_futures, :api_key)}
    ]

    case do_unsigned_request(url, data, method, headers, is_testnet) do
      {:error, err} ->
        {:error, {:http_error, err}}

      {:ok, response} ->
        case Poison.decode(response.body) do
          {:ok, data} -> {:ok, data}
          {:error, err} -> {:error, {:poison_decode_error, err}}
        end
    end
  end

  defp do_unsigned_request(url, nil, method, headers, is_testnet) do
    endpoint = get_endpoint(is_testnet)

    apply(HTTPoison, method, [
      "#{endpoint}#{url}",
      headers
    ])
  end

  defp do_unsigned_request(url, data, :get, headers, is_testnet) do
    argument_string =
      data
      |> prepare_query_params()

    endpoint = get_endpoint(is_testnet)

    apply(HTTPoison, :get, [
      "#{endpoint}#{url}" <> "?#{argument_string}",
      headers
    ])
  end

  defp do_unsigned_request(url, body, method, headers, is_testnet) do
    endpoint = get_endpoint(is_testnet)

    apply(HTTPoison, method, [
      "#{endpoint}#{url}",
      body,
      headers
    ])
  end

  defp validate_credentials(nil, nil),
    do: {:error, {:config_missing, "Secret and API key missing"}}

  defp validate_credentials(nil, _api_key),
    do: {:error, {:config_missing, "Secret key missing"}}

  defp validate_credentials(_secret_key, nil),
    do: {:error, {:config_missing, "API key missing"}}

  defp validate_credentials(_secret_key, _api_key),
    do: :ok

  defp parse_response({:ok, response}) do
    response.body
    |> Poison.decode()
    |> parse_response_body
  end

  defp parse_response({:error, err}) do
    {:error, {:http_error, err}}
  end

  defp parse_response_body({:ok, data}) do
    case data do
      %{"code" => _c, "msg" => _m} = error -> {:error, error}
      _ -> {:ok, data}
    end
  end

  defp parse_response_body({:error, err}) do
    {:error, {:poison_decode_error, err}}
  end

  defp prepare_query_params(params) do
    params
    |> Map.to_list()
    |> Enum.map(fn x -> Tuple.to_list(x) |> Enum.join("=") end)
    |> Enum.join("&")
  end

  defp generate_signature(digest, key, argument_string),
    do: :crypto.mac(:hmac, digest, key, argument_string)
end
