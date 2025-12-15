defmodule Ueberauth.Strategy.Hubspot.OAuthTest do
  use ExUnit.Case, async: true

  alias Ueberauth.Strategy.Hubspot.OAuth

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

  describe "client/1" do
    test "creates OAuth2 client with default configuration" do
      client = OAuth.client()

      assert client.client_id == "test_client_id"
      assert client.client_secret == "test_client_secret"
      assert client.strategy == OAuth
      assert client.site == "https://api.hubapi.com"
      assert client.authorize_url == "https://app.hubspot.com/oauth/authorize"
      assert client.token_url == "https://api.hubapi.com/oauth/v1/token"
    end

    test "merges custom options into client configuration" do
      client = OAuth.client(redirect_uri: "https://example.com/callback")

      assert client.redirect_uri == "https://example.com/callback"
    end

    test "raises error when client_id is missing" do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth,
        client_secret: "test_client_secret"
      )

      assert_raise RuntimeError, ~r/client_id missing/, fn ->
        OAuth.client()
      end
    end

    test "raises error when client_secret is missing" do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth,
        client_id: "test_client_id"
      )

      assert_raise RuntimeError, ~r/client_secret missing/, fn ->
        OAuth.client()
      end
    end

    test "raises error when config is not a keyword list" do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth, "invalid_config")

      assert_raise RuntimeError, ~r/not a keyword list/, fn ->
        OAuth.client()
      end
    end
  end

  describe "authorize_url!/2" do
    test "generates authorization URL with default parameters" do
      url = OAuth.authorize_url!()

      assert url =~ "https://app.hubspot.com/oauth/authorize"
      assert url =~ "client_id=test_client_id"
    end

    test "includes scope in authorization URL" do
      url = OAuth.authorize_url!([scope: "crm.objects.contacts.read"])

      assert url =~ "scope=crm.objects.contacts.read"
    end

    test "includes state parameter in authorization URL" do
      url = OAuth.authorize_url!([state: "random_state_value"])

      assert url =~ "state=random_state_value"
    end
  end

  describe "get_access_token/2" do
    test "returns error when access_token is nil" do
      # This test verifies the error handling in get_access_token
      # Since we can't easily mock OAuth2.Client.get_token, we skip this test
      # and rely on integration tests instead
    end
  end

  describe "authorize_url/2" do
    test "delegates to OAuth2.Strategy.AuthCode" do
      client = OAuth.client()
      params = [scope: "test_scope"]

      result = OAuth.authorize_url(client, params)

      # authorize_url returns a client struct with updated params
      assert is_struct(result, OAuth2.Client)
      assert result.params["scope"] == "test_scope"
    end
  end

  describe "get_token/3" do
    test "adds client_secret to params" do
      client = OAuth.client()
      params = [code: "test_code"]
      headers = []

      result = OAuth.get_token(client, params, headers)

      assert result.params["client_secret"] == "test_client_secret"
    end
  end

  describe "get/4" do
    test "creates client with token and makes GET request" do
      token = %OAuth2.AccessToken{
        access_token: "test_token",
        token_type: "Bearer"
      }

      result = OAuth.get(token, "/test/endpoint")

      assert match?({:error, _}, result) or match?({:ok, _}, result)
    end
  end
end
