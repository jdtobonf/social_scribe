defmodule SocialScribe.MeetingTranscriptExample do
  def meeting_transcript_example do
    [
      %{
        participant: %{
          id: 100,
          name: "Felipe Gomes Paradas",
          is_host: true,
          platform: "desktop",
          email: nil,
          extra_data: nil
        },
        words: [
          %{
            text: "what I say later and then",
            start_timestamp: %{
              relative: 0.48204318,
              absolute: nil
            },
            end_timestamp: %{
              relative: 1.5677435,
              absolute: nil
            }
          },
          %{
            text: "It should be able to tell me.",
            start_timestamp: %{
              relative: 2.3654845,
              absolute: nil
            },
            end_timestamp: %{
              relative: 4.9698553,
              absolute: nil
            }
          },
          %{
            text: "What I spoke about in this meeting. Please do your job, correctly.",
            start_timestamp: %{
              relative: 5.494311,
              absolute: nil
            },
            end_timestamp: %{
              relative: 13.668149,
              absolute: nil
            }
          }
        ]
      }
    ]
  end
end
