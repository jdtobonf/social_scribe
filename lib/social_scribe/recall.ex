defmodule SocialScribe.Recall do
  @moduledoc "The real implementation for the Recall.ai API client."
  @behaviour SocialScribe.RecallApi

  defp client do
    api_key = Application.fetch_env!(:social_scribe, :recall_api_key)
    recall_region = Application.fetch_env!(:social_scribe, :recall_region)

    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://#{recall_region}.recall.ai/api/v1"},
      {Tesla.Middleware.JSON, engine_opts: [keys: :atoms]},
      {Tesla.Middleware.Headers,
       [
         {"Authorization", "Token #{api_key}"},
         {"Content-Type", "application/json"},
         {"Accept", "application/json"}
       ]}
    ])
  end

  @impl SocialScribe.RecallApi
  def create_bot(meeting_url, join_at) do
    body = %{
      meeting_url: meeting_url,
      # transcription_options: %{provider: "meeting_captions"},
      join_at: Timex.format!(join_at, "{ISO:Extended}")
    }

    Tesla.post(client(), "/bot", body)
  end

  @impl SocialScribe.RecallApi
  def update_bot(recall_bot_id, meeting_url, join_at) do
    body = %{
      meeting_url: meeting_url,
      join_at: Timex.format!(join_at, "{ISO:Extended}")
    }

    Tesla.patch(client(), "/bot/#{recall_bot_id}", body)
  end

  @impl SocialScribe.RecallApi
  def delete_bot(recall_bot_id) do
    Tesla.delete(client(), "/bot/#{recall_bot_id}")
  end

  @impl SocialScribe.RecallApi
  def get_bot(recall_bot_id) do
    Tesla.get(client(), "/bot/#{recall_bot_id}")
  end

  @impl SocialScribe.RecallApi
  def get_bot_transcript(recall_bot_id) do
    # API v1.11: Get bot info to find recording ID, then get or create transcript
    with {:ok, %Tesla.Env{body: bot_info}} <- get_bot(recall_bot_id),
         recording <- List.first(bot_info.recordings || []),
         recording_id <- Map.get(recording, :id) do
      # Check if transcript already exists in media_shortcuts
      case get_in(recording, [:media_shortcuts, :transcript]) do
        nil ->
          # No transcript exists, create one
          case create_transcript(recording_id, default_provider_config()) do
            {:ok, %Tesla.Env{body: transcript_info}} ->
              transcript_id = Map.get(transcript_info, :id)
              wait_for_transcript_completion(transcript_id)
            error ->
              error
          end

        transcript_shortcut ->
          # Transcript exists, check its status
          transcript_id = Map.get(transcript_shortcut, :id)
          status = get_in(transcript_shortcut, [:status, :code])

          case status do
            "done" ->
              # Transcript is ready, fetch it
              case get_transcript(transcript_id) do
                {:ok, %Tesla.Env{body: transcript_info}} ->
                  download_url = get_in(transcript_info, [:data, :download_url])
                  if download_url do
                    case Tesla.get(download_url) do
                      {:ok, %Tesla.Env{body: json_body}} ->
                        case Jason.decode(json_body, keys: :atoms) do
                          {:ok, parsed_data} ->
                            {:ok, %Tesla.Env{body: parsed_data}}
                          {:error, reason} ->
                            {:error, {:json_decode_failed, reason}}
                        end
                      error ->
                        error
                    end
                  else
                    {:error, :no_download_url}
                  end
                error ->
                  error
              end

            "error" ->
              {:error, :transcript_failed}

            _ ->
              # Transcript is still processing, wait for it
              wait_for_transcript_completion(transcript_id)
          end
      end
    end
  end

  @impl SocialScribe.RecallApi
  def create_transcript(recording_id, provider_config) do
    body = %{
      provider: provider_config,
      diarization: %{
        use_separate_streams_when_available: true
      }
    }

    Tesla.post(client(), "/recording/#{recording_id}/create_transcript/", body)
  end

  @impl SocialScribe.RecallApi
  def get_transcript(transcript_id) do
    Tesla.get(client(), "/transcript/#{transcript_id}/")
  end

  # Helper functions
  defp default_provider_config do
    %{
      recallai_async: %{
        language_code: "en"
      }
    }
  end

  defp wait_for_transcript_completion(transcript_id, attempts \\ 0, max_attempts \\ 30) do
    if attempts >= max_attempts do
      {:error, :transcript_timeout}
    else
      case get_transcript(transcript_id) do
        {:ok, %Tesla.Env{body: transcript_info}} ->
          status = get_in(transcript_info, [:status, :code])

          case status do
            "done" ->
              # Fetch the actual transcript data from download_url
              download_url = get_in(transcript_info, [:data, :download_url])
              if download_url do
                case Tesla.get(download_url) do
                  {:ok, %Tesla.Env{body: json_body}} ->
                    case Jason.decode(json_body, keys: :atoms) do
                      {:ok, parsed_data} ->
                        {:ok, %Tesla.Env{body: parsed_data}}
                      {:error, reason} ->
                        {:error, {:json_decode_failed, reason}}
                    end
                  error ->
                    error
                end
              else
                {:error, :no_download_url}
              end

            "error" ->
              {:error, :transcript_failed}

            _ ->
              # Still processing, wait and retry
              Process.sleep(2000)
              wait_for_transcript_completion(transcript_id, attempts + 1, max_attempts)
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
