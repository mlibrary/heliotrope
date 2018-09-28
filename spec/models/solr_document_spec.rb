# frozen_string_literal: true

require 'rails_helper'

describe SolrDocument do
  let(:instance) { described_class.new(attributes) }

  describe "#date_published" do
    subject { instance.date_published }

    let(:attributes) { { 'date_published_tesim' => ['Oct 20th'] } }

    it { is_expected.to eq ['Oct 20th'] }
  end

  describe "#allow_display_after_expiration" do
    subject { instance.allow_display_after_expiration }

    let(:attributes) { { 'allow_display_after_expiration_ssim' => ['yes'] } }

    it { is_expected.to eq 'yes' }
  end

  # Monograph + FileSet
  it { is_expected.to respond_to(:copyright_holder) }
  it { is_expected.to respond_to(:date_published) }
  it { is_expected.to respond_to(:doi) }
  it { is_expected.to respond_to(:hdl) }
  it { is_expected.to respond_to(:has_model) }
  it { is_expected.to respond_to(:holding_contact) }

  # Monograph
  it { is_expected.to respond_to(:creator) }
  it { is_expected.to respond_to(:contributor) }
  it { is_expected.to respond_to(:creator_display) }
  it { is_expected.to respond_to(:creator_full_name) }
  it { is_expected.to respond_to(:buy_url) }
  it { is_expected.to respond_to(:isbn) }
  it { is_expected.to respond_to(:press) }

  # FileSet
  it { is_expected.to respond_to(:allow_display_after_expiration) }
  it { is_expected.to respond_to(:allow_download) }
  it { is_expected.to respond_to(:allow_download_after_expiration) }
  it { is_expected.to respond_to(:allow_hi_res) }
  it { is_expected.to respond_to(:alt_text) }
  it { is_expected.to respond_to(:caption) }
  it { is_expected.to respond_to(:content_type) }
  it { is_expected.to respond_to(:copyright_status) }
  it { is_expected.to respond_to(:credit_line) }
  it { is_expected.to respond_to(:display_date) }
  it { is_expected.to respond_to(:exclusive_to_platform) }
  it { is_expected.to respond_to(:external_resource_url) }
  it { is_expected.to respond_to(:redirect_to) }
  it { is_expected.to respond_to(:keywords) }
  it { is_expected.to respond_to(:permissions_expiration_date) }
  it { is_expected.to respond_to(:primary_creator_role) }
  it { is_expected.to respond_to(:resource_type) }
  it { is_expected.to respond_to(:rights_granted) }
  it { is_expected.to respond_to(:license) }
  it { is_expected.to respond_to(:section_title) }
  it { is_expected.to respond_to(:sort_date) }
  it { is_expected.to respond_to(:transcript) }
  it { is_expected.to respond_to(:translation) }
end
