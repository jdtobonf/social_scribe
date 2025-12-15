defmodule Ueberauth.Strategy.Hubspot do
  @moduledoc """
  HubSpot Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    uid_field: :user_id,
    default_scope:
      "crm.objects.contacts.read crm.schemas.contacts.write crm.objects.contacts.write crm.schemas.contacts.read",
    oauth2_module: Ueberauth.Strategy.Hubspot.OAuth

  import Ueberauth.Strategy.Helpers

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for HubSpot authentication.
  """
  def handle_request!(conn) do
    scopes =
      Map.get(conn.params, "scope") ||
        options(conn)[:default_scope] ||
        "crm.objects.contacts.read crm.schemas.contacts.write crm.objects.contacts.write crm.schemas.contacts.read"

    params =
      [scope: scopes]
      |> with_state_param(conn)

    opts = []
    redirect!(conn, Ueberauth.Strategy.Hubspot.OAuth.authorize_url!(params, opts))
  end

  @doc """
  Handles the callback from HubSpot.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    params = [code: code]
    opts = []

    case Ueberauth.Strategy.Hubspot.OAuth.get_access_token(params, opts) do
      {:ok, token} ->
        fetch_user(conn, token)

      {:error, {error_code, error_description}} ->
        set_errors!(conn, [error(error_code, error_description)])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("oauth2_error", inspect(reason))])

      {:error, %OAuth2.Response{} = response} ->
        set_errors!(conn, [error("oauth2_response_error", "Status: #{response.status_code}")])

      error ->
        set_errors!(conn, [error("unknown_error", inspect(error))])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:hubspot_user, nil)
    |> put_private(:hubspot_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    case Map.get(conn.private, :hubspot_user) do
      nil -> nil
      user -> user["user_id"]
    end
  end

  @doc """
  Includes the credentials from the HubSpot response.
  """
  def credentials(conn) do
    token = conn.private.hubspot_token
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, " ")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token_type: Map.get(token, :token_type),
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.hubspot_user

    %Info{
      email: user["user"],
      name: user["user"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the HubSpot callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.hubspot_token,
        user: conn.private.hubspot_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :hubspot_token, token)

    resp =
      Ueberauth.Strategy.Hubspot.OAuth.get(token, "/oauth/v1/access-tokens/#{token.access_token}")

    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: body}} ->
        set_errors!(conn, [error("token", "unauthorized" <> inspect(body))])

      {:ok, %OAuth2.Response{status_code: status_code, body: user_info}}
      when status_code in 200..399 ->
        parsed_user_info =
          if is_binary(user_info) do
            Jason.decode!(user_info)
          else
            user_info
          end

        put_private(conn, :hubspot_user, parsed_user_info)

      {:error, %OAuth2.Response{status_code: status_code}} ->
        set_errors!(conn, [error("OAuth2", status_code)])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end
end
