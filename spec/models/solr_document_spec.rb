# frozen_string_literal: true

require 'rails_helper'

describe SolrDocument do
  let(:instance) { described_class.new(attributes) }

  it('includes SolrDocumentExtensions') { is_expected.to be_a SolrDocumentExtensions }

  describe "#date_published" do
    subject { instance.date_published }

    let(:attributes) { { 'date_published_dtsim' => ['2019-04-11T18:24:53Z'] } }

    it { is_expected.to eq '2019-04-11' }
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
  it { is_expected.to respond_to(:tombstone) }
  it { is_expected.to respond_to(:tombstone_message) }

  # Monograph
  it { is_expected.to respond_to(:creator) }
  it { is_expected.to respond_to(:contributor) }
  it { is_expected.to respond_to(:creator_display) }
  it { is_expected.to respond_to(:creator_full_name) }
  it { is_expected.to respond_to(:buy_url) }
  it { is_expected.to respond_to(:isbn) }
  it { is_expected.to respond_to(:press) }
  it { is_expected.to respond_to(:open_access) }
  it { is_expected.to respond_to(:funder) }
  it { is_expected.to respond_to(:funder_display) }

  # FileSet
  it { is_expected.to respond_to(:allow_display_after_expiration) }
  it { is_expected.to respond_to(:allow_download) }
  it { is_expected.to respond_to(:allow_download_after_expiration) }
  it { is_expected.to respond_to(:allow_hi_res) }
  it { is_expected.to respond_to(:alt_text) }
  it { is_expected.to respond_to(:caption) }
  it { is_expected.to respond_to(:closed_captions) }
  it { is_expected.to respond_to(:content_type) }
  it { is_expected.to respond_to(:copyright_status) }
  it { is_expected.to respond_to(:credit_line) }
  it { is_expected.to respond_to(:display_date) }
  it { is_expected.to respond_to(:exclusive_to_platform) }
  it { is_expected.to respond_to(:external_resource_url) }
  it { is_expected.to respond_to(:keywords) }
  it { is_expected.to respond_to(:license) }
  it { is_expected.to respond_to(:permissions_expiration_date) }
  it { is_expected.to respond_to(:primary_creator_role) }
  it { is_expected.to respond_to(:redirect_to) }
  it { is_expected.to respond_to(:resource_type) }
  it { is_expected.to respond_to(:rights_granted) }
  it { is_expected.to respond_to(:section_title) }
  it { is_expected.to respond_to(:sort_date) }
  it { is_expected.to respond_to(:transcript) }
  it { is_expected.to respond_to(:translation) }
  it { is_expected.to respond_to(:visual_descriptions) }

  describe "#oai_doi" do
    subject { instance.oai_doi }

    let(:attributes) { { 'doi_ssim' => ['10.3998/fulcrum.999999999'] } }

    it { is_expected.to eq "https://doi.org/10.3998/fulcrum.999999999" }
  end

  describe "#oai_handle" do
    subject { instance.oai_handle }

    context "with a saved handle" do
      let(:attributes) { { 'hdl_ssim' => ['2027/heb.32971'] } }

      it { is_expected.to eq 'https://hdl.handle.net/2027/heb.32971' }
    end

    context "with a handle in the identifier field (heb only)" do
      let(:attributes) { { 'identifier_ssim' => ['heb.32971.0001.001', 'https://hdl.handle.net/2027/heb.32971'] } }

      it { is_expected.to be nil }
    end

    context "returns the default fulcrum handle" do
      let(:attributes) { { 'id' => '999999999' } }

      it { is_expected.to eq 'https://hdl.handle.net/2027/fulcrum.999999999' }
    end
  end

  describe "#oai_description" do
    subject { instance.oai_description }

    context "with a markdown description" do
      let(:attributes) { { 'description_tesim' => ['I have _markdown_!'] } }

      it { is_expected.to eq 'I have markdown!' }
    end

    context "with no description" do
      let(:attributes) { { 'id' => '999999999' } }

      it { is_expected.to eq nil }
    end
  end
end
