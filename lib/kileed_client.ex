defmodule KileedClient do
  @moduledoc """
  Kileed client

  This module helps interacting with a kileed authentication service.
  """

  require Logger

  @kileed_server_url Application.get_env(:kileed_client, :server_url)
  @auth_header Application.get_env(:kileed_client, :auth_token)
  @timeout Application.get_env(:kileed_client, :timeout, 20_000)

  @start_auth_addr "/start_auth"
  @commit_auth_addr "/commit_auth"

  @type errors ::
          :unknown
          | :service_blocked_ip
          | :service_auth
          | :property_blocked
          | :client_blocked_ip
          | :delivery_error

  @type kileed_session :: %{
          id: integer(),
          login_on: String.t(),
          valid_from: DateTime.t(),
          valid_until: DateTime.t(),
          user_id: integer(),
          validate_by_request: integer(),
          service_id: integer
        }

  @doc """
  Starts authorizing a kileed session with phone number.

  ## Parameters
    - phone_number: The client phone number to authorize
    - client_uid: A unique identifire of client. (Usually the client IP Address)
  """
  @spec start_challenge(String.t(), String.t()) :: :ok | {:error, errors()}
  def start_challenge(phone_number, client_uid) do
    url = Path.join(@kileed_server_url, @start_auth_addr)
    req = %{"type" => "phone", "property" => phone_number, "client_ip" => client_uid}

    {:ok, response} =
      HTTPoison.post(
        url,
        Poison.encode!(req),
        [Authorization: @auth_header, "Content-Type": "application/json"],
        timeout: @timeout
      )

    case response do
      %HTTPoison.Response{status_code: 200} ->
        :ok

      %{body: body} ->
        case Poison.decode(body) do
          {:ok, %{"errors" => errors}} ->
            error =
              errors
              |> List.first()
              |> Map.get("type")
              |> String.downcase()
              |> String.to_atom()

            {:error, error}

          _ ->
            {:error, :unknown}
        end

      _ ->
        {:error, :unknown}
    end
  end

  @doc """
  Tries to validate and commit user's answer to challenge.

  ## Parameters
    - phone_number: The phone number to commit challenge. (Same as the one which
    challenge started with
    - challenge_answer: User's answer to chanllenge as string.
    - client_uid: Client's unique identifire. (Usually the IP Address)
  """
  @spec commit_challenge(String.t(), String.t(), String.t()) ::
          {:ok, %{user_id: integer, session: kileed_session}} | {:error, errors()}
  def commit_challenge(phone_number, challenge_answer, client_uid) do
    url = Path.join(@kileed_server_url, @commit_auth_addr)

    req = %{
      type: "phone",
      property: phone_number,
      answer: challenge_answer,
      client_ip: client_uid
    }

    {:ok, response} =
      HTTPoison.post(
        url,
        Poison.encode!(req),
        [Authorization: @auth_header, "Content-Type": "application/json"],
        timeout: @timeout
      )

    case response do
      %HTTPoison.Response{status_code: 200, body: body} ->
        auth_result = Poison.decode!(body)
        {:ok, auth_result}

      %{body: body} ->
        errors = Poison.decode(body)

        error_data =
          case errors do
            {:ok, json} ->
              json

            _ ->
              Logger.error(inspect(body))
              %{"error" => %{"code" => "unknown"}}
          end

        error =
          cond do
            Map.has_key?(error_data, "errors") ->
              String.to_atom(List.first(error_data["errors"])["type"])

            Map.has_key?(error_data, "error") ->
              String.to_atom(error_data["error"]["code"])

            true ->
              :unknown
          end

        {:error, error}

      _ ->
        {:error, :unknown}
    end
  end
end
