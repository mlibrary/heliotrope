# frozen_string_literal: true

require 'rails_helper'
require 'export'

describe Export::Exporter do
  describe '#new' do
    subject { described_class.new(monograph_id) }

    let(:monograph_id) { 'validnoid' }

    context 'monograph not found' do
      it { expect { subject }.to raise_error(ActiveFedora::ObjectNotFoundError) }
    end

    context 'monograph' do
      let(:monograph) { double('monograph') }
      before { allow(Monograph).to receive(:find).with(monograph_id).and_return(monograph) }
      it { is_expected.to be_an_instance_of(described_class) }
    end
  end

  describe '#export' do
    subject { described_class.new(monograph.id).export }

    let(:monograph) { build(:monograph, representative_id: cover.id) }
    let(:cover) { create(:file_set) }
    let(:file1) { create(:file_set) }
    let(:file2) { create(:file_set) }
    let(:expected) do
      <<~eos
        NOID,File Name,Link,Title,Resource Type,Externally Hosted Resource,Caption,Alternative Text,Copyright Holder,Allow High-Res Display?,Allow Download?,Copyright Status,Rights Granted,Rights Granted - Creative Commons,Permissions Expiration Date,After Expiration: Allow Display?,After Expiration: Allow Download?,Credit Line,Holding Contact,Exclusive to Fulcrum,Persistent ID - Display on Platform,Persistent ID - XML for CrossRef,Persistent ID - Handle,Handle,DOI,Content Type,Primary Creator Last Name,Primary Creator First Name,Primary Creator Role,Additional Creator(s),Sort Date,Display Date,Description,Keywords,Section,Language,Transcript,Translation,Redirect to,Publisher,Subject,ISBN (hardcover),ISBN (paper),ISBN (ebook),Buy Book URL,Pub Year,Pub Location
        instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder
        #{cover.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(cover)}"")",#{cover.title.first},#{cover.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,,,,#{cover.sort_date},,,,,,,,,,,,,,,,
        #{file1.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file1)}"")",#{file1.title.first},#{file1.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,,,,#{file1.sort_date},,,,,,,,,,,,,,,,
        #{file2.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file2)}"")",#{file2.title.first},#{file2.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,,,,#{file2.sort_date},,,,,,,,,,,,,,,,
        #{monograph.id},://:MONOGRAPH://:,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_monograph_url(monograph)}"")",#{monograph.title.first},,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,://:MONOGRAPH://:,,,,,,,,,,,,
      eos
    end

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file1
      monograph.ordered_members << file2
      monograph.save!
    end

    it do
      actual = subject
      # puts actual
      expect(actual.empty?).to be false
      expect(actual).to match expected
    end
  end
end
