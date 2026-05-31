# frozen_string_literal: true
require 'rails_helper'

describe ActiveEncode::EncodeRecordController, type: :controller, db_clean: true do
  routes { ActiveEncode::Engine.routes }

  let(:encode_record) { ActiveEncode::EncodeRecord.create(id: 1, global_id: "app://ActiveEncode/Encode/1", state: "running", adapter: "ffmpeg", title: "Test", raw_object: raw_object, progress: 100) }
  let(:raw_object) do
    "{\"input\":{\"url\":\"file:///Users/cjcolvar/Documents/Code/samvera/active_encode/spec/fixtures/fireworks.mp4\",\"width\":960.0,\"height\":540.0,\"frame_rate\":29.671,\"duration\":6024,\"file_size\":1629578,\"audio_codec\":\"mp4a-40-2\",\"video_codec\":\"avc1\",\"audio_bitrate\":69737,\"video_bitrate\":2092780,\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:50.401-05:00\",\"id\":\"8156\"},\"options\":{},\"id\":\"35efa965-ec51-409d-9495-2ae9669adbcc\",\"output\":[{\"url\":\"file:///Users/cjcolvar/Documents/Code/samvera/active_encode/.internal_test_app/encodes/35efa965-ec51-409d-9495-2ae9669adbcc/outputs/fireworks-low.mp4\",\"label\":\"low\",\"id\":\"8156-low\",\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:59.169-05:00\",\"width\":640.0,\"height\":480.0,\"frame_rate\":29.671,\"duration\":6038,\"file_size\":905987,\"audio_codec\":\"mp4a-40-2\",\"video_codec\":\"avc1\",\"audio_bitrate\":72000,\"video_bitrate\":1126859},{\"url\":\"file:///Users/cjcolvar/Documents/Code/samvera/active_encode/.internal_test_app/encodes/35efa965-ec51-409d-9495-2ae9669adbcc/outputs/fireworks-high.mp4\",\"label\":\"high\",\"id\":\"8156-high\",\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:59.169-05:00\",\"width\":1280.0,\"height\":720.0,\"frame_rate\":29.671,\"duration\":6038,\"file_size\":2102027,\"audio_codec\":\"mp4a-40-2\",\"video_codec\":\"avc1\",\"audio_bitrate\":72000,\"video_bitrate\":2721866}],\"state\":\"completed\",\"errors\":[],\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:59.169-05:00\",\"current_operations\":[],\"percent_complete\":100,\"global_id\":{\"uri\":\"gid://ActiveEncode/Encode/35efa965-ec51-409d-9495-2ae9669adbcc\"}}"
  end

  before do
    encode_record
  end

  describe 'GET show' do
    before do
      get :show, params: { id: record_id }
    end

    context 'when record exists' do
      let(:record_id) { 1 }

      it "responds with a 200 status code" do
        expect(response.status).to eq 200
      end

      it "responds with JSON" do
        expect(response.content_type).to include "application/json"
      end

      it "returns the encode record's raw json object" do
        expect(response.body).to eq raw_object
      end
    end

    context 'when record does not exist' do
      let(:record_id) { "non-existant" }

      it "responds with a 404 status code" do
        expect(response.status).to eq 404
      end

      it "responds with JSON" do
        expect(response.content_type).to include "application/json"
      end

      it "returns the encode record's raw json object" do
        expect(response.body).to eq "{\"message\":\"Couldn't find ActiveEncode::EncodeRecord with 'id'=#{record_id}\"}"
      end
    end
  end
end
