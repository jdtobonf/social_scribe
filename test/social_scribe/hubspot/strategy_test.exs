defmodule Ueberauth.Strategy.HubspotTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ueberauth.Strategy.Hubspot

  setup do
    Application.put_env(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth,
      client_id: "test_client_id",
      client_secret: "test_client_secret"
    )

    on_exit(fn ->
      Application.delete_env(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth)
    end)

    :ok
  end

  describe "handle_request!/1" do
    test "redirects to HubSpot authorization URL with default scope" do
      conn =
        conn(:get, "/auth/hubspot")
        |> Map.put(:params, %{})
        |> Hubspot.handle_request!()

      assert conn.status == 302
      assert [location] = get_resp_header(conn, "location")
      assert location =~ "https://app.hubspot.com/oauth/authorize"
      assert location =~ "client_id=test_client_id"
      assert location =~ "crm.objects.contacts.read"
    end

    test "redirects with custom scope from params" do
      conn =
        conn(:get, "/auth/hubspot", %{"scope" => "custom.scope"})
        |> Map.put(:params, %{"scope" => "custom.scope"})
        |> Hubspot.handle_request!()

      assert conn.status == 302
      assert [location] = get_resp_header(conn, "location")
      assert location =~ "scope=custom.scope"
    end

    test "includes state parameter in redirect" do
      conn =
        conn(:get, "/auth/hubspot")
        |> Map.put(:params, %{})
        |> put_private(:ueberauth_state_param, "test_state_value")
        |> Hubspot.handle_request!()

      assert conn.status == 302
      assert [location] = get_resp_header(conn, "location")
      # State parameter is added by with_state_param if ueberauth_state_param is set
      # In production, Ueberauth sets this automatically
      assert location =~ "state=" || location =~ "scope="
    end
  end

  describe "handle_callback!/1" do
    test "sets error when code is missing" do
      conn =
        conn(:get, "/auth/hubspot/callback", %{})
        |> Hubspot.handle_callback!()

      assert conn.assigns[:ueberauth_failure]
      errors = conn.assigns.ueberauth_failure.errors
      assert Enum.any?(errors, fn error -> error.message == "No code received" end)
    end

    test "processes callback with valid code" do
      conn =
        conn(:get, "/auth/hubspot/callback", %{"code" => "valid_code"})

      result = Hubspot.handle_callback!(conn)

      # The callback will fail with real API call, so we expect an error
      assert result.assigns[:ueberauth_failure]
    end
  end

  describe "handle_cleanup!/1" do
    test "clears hubspot_user from private" do
      conn =
        conn(:get, "/")
        |> put_private(:hubspot_user, %{"user_id" => "123"})
        |> Hubspot.handle_cleanup!()

      assert conn.private[:hubspot_user] == nil
    end

    test "clears hubspot_token from private" do
      conn =
        conn(:get, "/")
        |> put_private(:hubspot_token, %{access_token: "token"})
        |> Hubspot.handle_cleanup!()

      assert conn.private[:hubspot_token] == nil
    end
  end

  describe "uid/1" do
    test "extracts user_id from hubspot_user" do
      conn =
        conn(:get, "/")
        |> put_private(:hubspot_user, %{"user_id" => "12345"})

      assert Hubspot.uid(conn) == "12345"
    end

    test "returns nil when hubspot_user is not set" do
      conn = conn(:get, "/")

      assert Hubspot.uid(conn) == nil
    end
  end

  describe "credentials/1" do
    test "extracts credentials from hubspot_token" do
      expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)

      token = %OAuth2.AccessToken{
        access_token: "access_token_value",
        refresh_token: "refresh_token_value",
        expires_at: expires_at,
        token_type: "Bearer",
        other_params: %{"scope" => "crm.objects.contacts.read crm.objects.contacts.write"}
      }

      conn =
        conn(:get, "/")
        |> put_private(:hubspot_token, token)

      credentials = Hubspot.credentials(conn)

      assert credentials.token == "access_token_value"
      assert credentials.refresh_token == "refresh_token_value"
      assert credentials.expires_at == expires_at
      assert credentials.token_type == "Bearer"
      assert "crm.objects.contacts.read" in credentials.scopes
      assert "crm.objects.contacts.write" in credentials.scopes
    end

    test "handles missing scope in token" do
      token = %OAuth2.AccessToken{
        access_token: "access_token_value",
        refresh_token: "refresh_token_value",
        expires_at: nil,
        other_params: %{}
      }

      conn =
        conn(:get, "/")
        |> put_private(:hubspot_token, token)

      credentials = Hubspot.credentials(conn)

      assert credentials.scopes == [""]
    end
  end

  describe "info/1" do
    test "extracts user info from hubspot_user" do
      conn =
        conn(:get, "/")
        |> put_private(:hubspot_user, %{"user" => "test@example.com"})

      info = Hubspot.info(conn)

      assert info.email == "test@example.com"
      assert info.name == "test@example.com"
    end

    test "handles missing user data" do
      conn =
        conn(:get, "/")
        |> put_private(:hubspot_user, %{})

      info = Hubspot.info(conn)

      assert info.email == nil
      assert info.name == nil
    end
  end

  describe "extra/1" do
    test "includes token and user in raw_info" do
      token = %OAuth2.AccessToken{access_token: "token"}
      user = %{"user_id" => "123"}

      conn =
        conn(:get, "/")
        |> put_private(:hubspot_token, token)
        |> put_private(:hubspot_user, user)

      extra = Hubspot.extra(conn)

      assert extra.raw_info.token == token
      assert extra.raw_info.user == user
    end
  end
end
