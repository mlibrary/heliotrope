# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YouTubeVideoInfoService do
  let(:file_set) { create(:file_set, identifier: identifier) }
  let(:identifier) { nil }

  describe "Returned YouTube Video Data" do
    subject { described_class.get_yt_video_data(file_set.id) }

    context 'no YouTube ID present' do
      it { is_expected.to be_nil }
    end

    context 'youtube_id present in identifier' do
      context 'bad YT ID' do
        let(:identifier) { ['youtube_id: badyoutubeid'] }
        let(:oembed_json) { 'Bad Request' }

        before do
          oembed_response = Net::HTTPBadRequest.new(1.0, '400', body: oembed_json)
          allow(oembed_response).to receive(:body).and_return(oembed_json)
          allow(Net::HTTP)
            .to receive(:get_response)
                  .with(URI("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=badyoutubeid&format=json"))
                  .and_return(oembed_response)
        end

        it { is_expected.to be_nil }
      end

      context 'good YT ID' do
        let(:identifier) { ['youtube_id: goodyoutubeid'] }
        # unused values are omitted from this oEmbed JSON snippet
        let(:oembed_json) { '{"height":113,"width":200}' }
        let(:youtube_video_page_body) { "<body>...</body>" }

        before do
          oembed_response = Net::HTTPSuccess.new(1.0, '200', body: oembed_json)
          allow(oembed_response).to receive(:body).and_return(oembed_json)
          allow(Net::HTTP)
            .to receive(:get_response)
                  .with(URI("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=goodyoutubeid&format=json"))
                  .and_return(oembed_response)

          youtube_video_page_response = Net::HTTPSuccess.new(1.0, '200', body: youtube_video_page_body)
          allow(youtube_video_page_response).to receive(:body).and_return(youtube_video_page_body)
          allow(Net::HTTP)
            .to receive(:get_response)
                  .with(URI("https://www.youtube.com/watch?v=goodyoutubeid"))
                  .and_return(youtube_video_page_response)
        end

        context 'video page has neither the Open Graph dimensions or the captions JSON' do
          it 'uses the oEmbed dimensions (x5), sets captions to false' do
            is_expected.to eq({ "captions_present" => false, "height" => 565, "id" => "goodyoutubeid", "use_able_player" => false, "width" => 1000 })
          end

          context 'set metadata to force use of able player for developer testing' do
            let(:identifier) { ['able_player_youtube_id: goodyoutubeid'] }

            it 'sets `use_able_player` to true' do
              is_expected.to eq({ "captions_present" => false, "height" => 565, "id" => "goodyoutubeid", "use_able_player" => true, "width" => 1000 })
            end
          end
        end

        context 'video page has both Open Graph dimensions and captions JSON' do
          let(:youtube_video_page_body) do
            <<~YOUTUBE_VIDEO_PAGE_BODY
              <body>
                ...
                <meta property="og:video:width" content="1280"><meta property="og:video:height" content="720">
                ...
                "captions":{"playerCaptionsTracklistRenderer":{"captionTracks":[{"baseUrl":"https://www.youtube.com/api/timedtext?v=goodyoutubeid...
                ...
              </body>
            YOUTUBE_VIDEO_PAGE_BODY
          end

          it 'returns the video page captions and dimensions information' do
            is_expected.to eq({ "captions_present" => true, "height" => 720, "id" => "goodyoutubeid", "use_able_player" => false, "width" => 1280 })
          end

          context 'set metadata to force use of able player for developer testing' do
            let(:identifier) { ['able_player_youtube_id: goodyoutubeid'] }

            it 'sets `use_able_player` to true' do
              is_expected.to eq({ "captions_present" => true, "height" => 720, "id" => "goodyoutubeid", "use_able_player" => true, "width" => 1280 })
            end
          end
        end
      end
    end
  end
end
