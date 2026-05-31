require 'spec_helper'

describe Hydra::Works::Characterization do
  let(:file) { Hydra::PCDM::File.new }

  describe "properties" do
    subject { file }
    context "with inhereited terms from ActiveFedora" do
      it { is_expected.to respond_to(:label) }
      it { is_expected.to respond_to(:file_name) }
      it { is_expected.to respond_to(:file_size) }
      it { is_expected.to respond_to(:date_created) }
      it { is_expected.to respond_to(:mime_type) }
      it { is_expected.to respond_to(:date_modified) }
      it { is_expected.to respond_to(:byte_order) }
    end
    context "with Base schema" do
      it { is_expected.to respond_to(:format_label) }
      it { is_expected.to respond_to(:file_size) }
      it { is_expected.to respond_to(:well_formed) }
      it { is_expected.to respond_to(:valid) }
      it { is_expected.to respond_to(:date_created) }
      it { is_expected.to respond_to(:fits_version) }
      it { is_expected.to respond_to(:exif_version) }
      it { is_expected.to respond_to(:original_checksum) }
    end
    context "with Image schema" do
      it { is_expected.to respond_to(:byte_order) }
      it { is_expected.to respond_to(:compression) }
      it { is_expected.to respond_to(:height) }
      it { is_expected.to respond_to(:width) }
      it { is_expected.to respond_to(:color_space) }
      it { is_expected.to respond_to(:profile_name) }
      it { is_expected.to respond_to(:profile_version) }
      it { is_expected.to respond_to(:orientation) }
      it { is_expected.to respond_to(:color_map) }
      it { is_expected.to respond_to(:image_producer) }
      it { is_expected.to respond_to(:capture_device) }
      it { is_expected.to respond_to(:scanning_software) }
      it { is_expected.to respond_to(:gps_timestamp) }
      it { is_expected.to respond_to(:latitude) }
      it { is_expected.to respond_to(:longitude) }
    end
    context "with Document schema" do
      it { is_expected.to respond_to(:file_title) }
      it { is_expected.to respond_to(:creator) }
      it { is_expected.to respond_to(:page_count) }
      it { is_expected.to respond_to(:language) }
      it { is_expected.to respond_to(:word_count) }
      it { is_expected.to respond_to(:character_count) }
      it { is_expected.to respond_to(:line_count) }
      it { is_expected.to respond_to(:character_set) }
      it { is_expected.to respond_to(:markup_basis) }
      it { is_expected.to respond_to(:markup_language) }
      it { is_expected.to respond_to(:paragraph_count) }
      it { is_expected.to respond_to(:table_count) }
      it { is_expected.to respond_to(:graphics_count) }
    end
    context "with Video schema" do
      it { is_expected.to respond_to(:height) }
      it { is_expected.to respond_to(:width) }
      it { is_expected.to respond_to(:frame_rate) }
      it { is_expected.to respond_to(:bit_rate) }
      it { is_expected.to respond_to(:duration) }
      it { is_expected.to respond_to(:sample_rate) }
      it { is_expected.to respond_to(:aspect_ratio) }
    end
    context "with Audio schema" do
      it { is_expected.to respond_to(:bit_depth) }
      it { is_expected.to respond_to(:channels) }
      it { is_expected.to respond_to(:data_format) }
      it { is_expected.to respond_to(:frame_rate) }
      it { is_expected.to respond_to(:bit_rate) }
      it { is_expected.to respond_to(:duration) }
      it { is_expected.to respond_to(:sample_rate) }
      it { is_expected.to respond_to(:offset) }
    end
  end

  describe "::mapper" do
    let(:mapper_keys) do
      [
        :file_author,
        :file_language,
        :file_mime_type,
        :audio_duration,
        :audio_sample_rate,
        :audio_bit_rate,
        :video_audio_sample_rate,
        :track_frame_rate,
        :video_duration,
        :video_sample_rate,
        :video_bit_rate,
        :video_width,
        :video_track_width,
        :video_height,
        :video_track_height
      ]
    end
    subject { described_class.mapper.keys }
    it { is_expected.to eq(mapper_keys) }
  end
end
