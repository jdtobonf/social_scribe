defmodule Ueberauth.Strategy.Hubspot.OAuth do
  @moduledoc """
  OAuth2 for HubSpot.

  Add `client_id` and `client_secret` to your configuration:

      config :ueberauth, Ueberauth.Strategy.Hubspot.OAuth,
        client_id: System.get_env("HUBSPOT_CLIENT_ID"),
        client_secret: System.get_env("HUBSPOT_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.hubapi.com",
    authorize_url: "https://app.hubspot.com/oauth/authorize",
    token_url: "https://api.hubapi.com/oauth/v1/token"
  ]

  @doc """
  Construct a client for requests to HubSpot.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.Hubspot.OAuth)
      |> check_config_key_exists(:client_id)
      |> check_config_key_exists(:client_secret)

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(client_opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_access_token(params \\ [], opts \\ []) do
    case opts |> client |> OAuth2.Client.get_token(params) do
      {:ok, %{token: %{access_token: nil}} = _client} ->
        %OAuth2.Error{reason: :no_access_token}

      {:ok, client} ->
        token = client.token

        # HubSpot returns token info as JSON in access_token field
        updated_token = if is_binary(token.access_token) and String.starts_with?(token.access_token, "{") do
          token_info = Jason.decode!(token.access_token)
          %{
            token |
            access_token: token_info["access_token"],
            refresh_token: token_info["refresh_token"],
            expires_at: DateTime.utc_now() |> DateTime.add(token_info["expires_in"], :second),
            other_params: Map.put(token.other_params, "hub_id", token_info["hub_id"])
          }
        else
          token
        end

        {:ok, updated_token}

      {:error, error} ->
        {:error, error}
    end
  end

  def get(token, url, headers \\ [], opts \\ []) do
    OAuth2.Client.get(
      %OAuth2.Client{
        token: token,
        site: "https://api.hubapi.com"
      },
      url,
      headers,
      opts
    )
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    case Keyword.fetch(config, key) do
      {:ok, _value} ->
        config

      :error ->
        raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.Hubspot.OAuth"
    end
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Hubspot.OAuth is not a keyword list, please provide a keyword list with client_id and client_secret"
  end
end
