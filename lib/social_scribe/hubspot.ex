defmodule SocialScribe.HubSpot do
  require Logger

  @base_url "https://api.hubapi.com"

  def client do
    middlewares = [
      {Tesla.Middleware.BaseUrl, @base_url},
      {Tesla.Middleware.FormUrlencoded,
       encode: &Plug.Conn.Query.encode/1, decode: &Plug.Conn.Query.decode/1},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middlewares)
  end

  def json_client do
    middlewares = [
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middlewares)
  end

  @doc """
  Refreshes a HubSpot access token using the refresh token.
  """
  def refresh_token(refresh_token) do
    client_id = Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth)[:client_id]
    client_secret = Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Hubspot.OAuth)[:client_secret]

    body = %{
      grant_type: "refresh_token",
      refresh_token: refresh_token,
      client_id: client_id,
      client_secret: client_secret
    }

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case Tesla.post(client(), "/oauth/v1/token", body, headers: headers, opts: [form_urlencoded: true]) do
      {:ok, %Tesla.Env{status: 200, body: response_body}} ->
        Logger.info("Successfully refreshed HubSpot token")

        # Parse the response
        %{
          "access_token" => new_access_token,
          "refresh_token" => new_refresh_token,
          "expires_in" => expires_in
        } = response_body

        expires_at = DateTime.utc_now() |> DateTime.add(expires_in, :second)

        {:ok, %{
          access_token: new_access_token,
          refresh_token: new_refresh_token,
          expires_at: expires_at
        }}

      {:ok, %Tesla.Env{status: status, body: error_body}} ->
        Logger.error("HubSpot Token Refresh API Error (Status: #{status}): #{inspect(error_body)}")
        {:error, "Failed to refresh token: #{status}"}

      {:error, reason} ->
        Logger.error("HubSpot Token Refresh HTTP Error: #{inspect(reason)}")
        {:error, "HTTP error refreshing token: #{inspect(reason)}"}
    end
  end

  @doc """
  Fetches contacts from HubSpot CRM for the given credential.
  Handles token refresh automatically if the token is expired.
  """
  def fetch_contacts(credential) do
    # Try with current token first
    case do_fetch_contacts(credential.token) do
      {:ok, contacts} ->
        {:ok, contacts}

      {:error, "Failed to fetch contacts: 401"} ->
        # Token expired, try to refresh
        Logger.info("Access token expired, attempting refresh for user #{credential.user_id}")

        case refresh_token(credential.refresh_token) do
          {:ok, token_data} ->
            # Update credential in database
            _updated_credential = %{
              credential |
              token: token_data.access_token,
              refresh_token: token_data.refresh_token,
              expires_at: token_data.expires_at
            }

            case SocialScribe.Accounts.update_user_credential(credential, %{
                   token: token_data.access_token,
                   refresh_token: token_data.refresh_token,
                   expires_at: token_data.expires_at
                 }) do
              {:ok, _updated_cred} ->
                # Retry fetch with new token
                do_fetch_contacts(token_data.access_token)

              {:error, changeset} ->
                Logger.error("Failed to update credential after refresh: #{inspect(changeset)}")
                {:error, "Failed to update refreshed token"}
            end

          {:error, reason} ->
            Logger.error("Failed to refresh token: #{reason}")
            {:error, "Token refresh failed: #{reason}"}
        end

      error ->
        error
    end
  end

  defp do_fetch_contacts(access_token) do
    url = "/crm/v3/objects/contacts"

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    case Tesla.get(client(), url, headers: headers) do
      {:ok, %Tesla.Env{status: 200, body: %{"results" => contacts}}} ->
        Logger.info("Successfully fetched #{length(contacts)} contacts from HubSpot")

        # Transform HubSpot contacts to the expected format
        transformed_contacts =
          Enum.map(contacts, fn contact ->
            properties = contact["properties"] || %{}
            %{
              id: contact["id"],
              firstname: properties["firstname"] || "",
              lastname: properties["lastname"] || "",
              email: properties["email"] || ""
            }
          end)

        {:ok, transformed_contacts}

      {:ok, %Tesla.Env{status: status, body: error_body}} ->
        Logger.error("HubSpot Contacts API Error (Status: #{status}): #{inspect(error_body)}")
        {:error, "Failed to fetch contacts: #{status}"}

      {:error, reason} ->
        Logger.error("HubSpot Contacts HTTP Error: #{inspect(reason)}")
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  @doc """
  Updates properties of a HubSpot contact.
  """
  def update_contact(credential, contact_id, properties) do
    url = "/crm/v3/objects/contacts/#{contact_id}"

    body = %{
      properties: properties
    }

    Logger.debug("Updating HubSpot contact #{contact_id} with body: #{inspect(body)}")

    case Tesla.patch(json_client(), url, body, headers: [{"Authorization", "Bearer #{credential.token}"}]) do
      {:ok, %Tesla.Env{status: 200, body: response_body}} ->
        Logger.info("Successfully updated HubSpot contact #{contact_id}")
        {:ok, response_body}

      {:ok, %Tesla.Env{status: status, body: error_body} = response} ->
        Logger.error("HubSpot Update Contact API Error (Status: #{status}): Body: #{inspect(error_body)}, Full response: #{inspect(response)}")
        {:error, "Failed to update contact: #{status}"}

      {:error, reason} ->
        Logger.error("HubSpot Update Contact HTTP Error: #{inspect(reason)}")
        {:error, "HTTP error updating contact: #{inspect(reason)}"}
    end
  end
end
