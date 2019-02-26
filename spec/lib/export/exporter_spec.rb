# frozen_string_literal: true

require 'rails_helper'
require 'export'

describe Export::Exporter do
  before do
    # Don't print status messages during specs
    allow($stdout).to receive(:puts)
  end

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

  describe '#export_bag' do
    subject { described_class.new(monograph.id).export_bag }

    let(:monograph) {
      create(:monograph, press: 'blue')
    }

    let(:monograph_bagit) {
      File.join(Settings.aptrust_bags_path, "umich.#{monograph.press}-#{monograph.id}")
    }

    let(:monograph_data) {
      File.join(Settings.aptrust_bags_path, "umich.#{monograph.press}-#{monograph.id}/data")
    }

    let(:monograph_aptrust_info) {
      File.join(Settings.aptrust_bags_path, "umich.#{monograph.press}-#{monograph.id}/aptrust-info.txt")
    }

    let(:monograph_bag_info) {
      File.join(Settings.aptrust_bags_path, "umich.#{monograph.press}-#{monograph.id}/bag-info.txt")
    }

    before do
      Dir.mkdir(Settings.aptrust_bags_path) unless Dir.exist?(Settings.aptrust_bags_path)
      Dir.mkdir("#{Settings.aptrust_bags_path}/data") unless Dir.exist?("#{Settings.aptrust_bags_path}/data")
    end

    after do
      FileUtils.rm_rf("#{Settings.aptrust_bags_path}/data") if Dir.exist?("#{Settings.aptrust_bags_path}/data")
      FileUtils.rm_rf(Settings.aptrust_bags_path) if Dir.exist?(Settings.aptrust_bags_path)
    end

    it do
      subject
      expect(File.exist?("#{monograph_bagit}.tar")).to be true
      expect(Dir.exist?(monograph_bagit)).to be false
      expect(Dir.exist?(monograph_data)).to be false
    end
  end

  describe '#export' do
    subject { described_class.new(monograph.id).export }

    let(:monograph) { build(:monograph, creator: ["First, Ms Joan\nSecond, Mr Tom"], contributor: ["Doe, Jane\nJoe, G.I."], doi: 'mpub.111111111.blah') }
    let(:file1) { create(:file_set, doi: 'mpub.222222222.blah') }
    let(:file2) { create(:file_set) }
    let(:file3) { create(:file_set) }
    let(:expected) do
      <<~eos
        NOID,File Name,Link,Title,Resource Type,External Resource URL,Caption,Alternative Text,Copyright Holder,Copyright Status,Open Access?,Funder,Allow High-Res Display?,Allow Download?,Rights Granted,CC License,Permissions Expiration Date,After Expiration: Allow Display?,After Expiration: Allow Download?,Credit Line,Holding Contact,Exclusive to Fulcrum,Identifier(s),Content Type,Creator(s),Additional Creator(s),Creator Display,Sort Date,Display Date,Description,Publisher,Subject,ISBN(s),Buy Book URL,Pub Year,Pub Location,Series,Keywords,Section,Language,Transcript,Translation,DOI,Handle,Redirect to,Representative Kind
        instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder
        #{file1.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file1)}"")",#{file1.title.first},#{file1.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,#{file1.sort_date},,,,,,,,,,,,,,,https://doi.org/mpub.222222222.blah,,,
        #{file2.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file2)}"")",#{file2.title.first},#{file2.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,#{file2.sort_date},,,,,,,,,,,,,,,,,,cover
        #{file3.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file3)}"")",#{file3.title.first},#{file3.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,#{file3.sort_date},,,,,,,,,,,,,,,,,,epub
        #{monograph.id},://:MONOGRAPH://:,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_monograph_url(monograph)}"")",#{monograph.title.first},,,,,,,,,,,,,,,,,,,,,"First, Ms Joan; Second, Mr Tom","Doe, Jane; Joe, G.I.",,,,,,,,,,,,,://:MONOGRAPH://:,,,,https://doi.org/mpub.111111111.blah,,,
      eos
    end

    before do
      monograph.ordered_members << file1
      monograph.ordered_members << file2
      monograph.ordered_members << file3
      monograph.representative_id = file2.id
      monograph.thumbnail_id = file2.id
      monograph.save!
      FeaturedRepresentative.create!(monograph_id: monograph.id, file_set_id: file3.id, kind: 'epub')
    end

    after { FeaturedRepresentative.destroy_all }

    it do
      actual = subject
      # puts actual
      expect(actual.empty?).to be false
      expect(actual).to match expected
    end
  end
end
