defmodule SocialScribe.HubSpotTest do
  use SocialScribe.DataCase, async: false

  alias SocialScribe.HubSpot
  alias SocialScribe.Accounts

  setup do
    Application.put_env(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth,
      client_id: "test_client_id",
      client_secret: "test_client_secret"
    )

    on_exit(fn ->
      Application.delete_env(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth)
    end)

    user = %{
      email: "test@example.com",
      hashed_password: Bcrypt.hash_pwd_salt("password123")
    }
    |> then(&struct!(SocialScribe.Accounts.User, &1))
    |> Repo.insert!()

    credential = %{
      user_id: user.id,
      provider: "hubspot",
      token: "valid_access_token",
      refresh_token: "valid_refresh_token",
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
    }
    |> then(&struct!(SocialScribe.Accounts.UserCredential, &1))
    |> Repo.insert!()

    {:ok, user: user, credential: credential}
  end

  describe "client/0" do
    test "creates Tesla client with correct base URL" do
      client = HubSpot.client()

      assert client.pre != []
      assert Enum.any?(client.pre, fn
        {Tesla.Middleware.BaseUrl, :call, ["https://api.hubapi.com"]} -> true
        _ -> false
      end)
    end

    test "includes JSON middleware" do
      client = HubSpot.client()

      assert Enum.any?(client.pre, fn
        {Tesla.Middleware.JSON, :call, _} -> true
        _ -> false
      end)
    end
  end

  describe "json_client/0" do
    test "creates Tesla client without form encoding" do
      client = HubSpot.json_client()

      assert client.pre != []
      refute Enum.any?(client.pre, fn
        {Tesla.Middleware.FormUrlencoded, :call, _} -> true
        _ -> false
      end)
    end
  end

  describe "refresh_token/1" do
    @tag :skip
    test "successfully refreshes token with valid refresh_token" do
      # This test requires actual HTTP mocking or integration testing
      # Skipped for unit tests - should be tested in integration tests
    end

    @tag :skip
    test "returns error when token refresh fails" do
      # This test requires actual HTTP mocking or integration testing
      # Skipped for unit tests - should be tested in integration tests
    end
  end

  describe "fetch_contacts/1" do
    @tag :skip
    test "successfully fetches contacts with valid token", %{credential: _credential} do
      # This test requires actual HTTP mocking or integration testing
      # Skipped for unit tests - should be tested in integration tests
    end

    @tag :skip
    test "handles token refresh and retry logic", %{credential: _credential} do
      # This test requires actual HTTP mocking or integration testing
      # Skipped for unit tests - should be tested in integration tests
    end
  end

  describe "update_contact/3" do
    @tag :skip
    test "successfully updates contact properties", %{credential: _credential} do
      # This test requires actual HTTP mocking or integration testing
      # Skipped for unit tests - should be tested in integration tests
    end

    @tag :skip
    test "handles error responses correctly", %{credential: _credential} do
      # This test requires actual HTTP mocking or integration testing
      # Skipped for unit tests - should be tested in integration tests
    end
  end
end
