# frozen_string_literal: true

require 'rails_helper'
require 'export'

describe Export::Exporter do
  before do
    # Don't print status messages during specs
    # allow($stdout).to receive(:puts)
  end

  describe '#new' do
    subject { described_class.new(monograph_id) }

    let(:monograph_id) { 'validnoid' }

    context 'monograph not found' do
      it { expect(subject.monograph).to be_nil }
    end

    context 'monograph' do
      let(:monograph) { double('monograph') }

      before { allow(Monograph).to receive(:find).with(monograph_id).and_return(monograph) }

      it { is_expected.to be_an_instance_of(described_class) }
    end
  end

  describe "#initialize" do
    subject { described_class.new(monograph.id) }

    let(:monograph) { create(:monograph) }

    it "initializes" do
      expect(subject.monograph.id).to eq monograph.id
      expect(subject.columns).to eq :all
    end
  end

  describe '#export' do
    subject { described_class.new(monograph.id).export }

    let(:monograph) { build(:monograph, creator: ["First, Ms Joan (editor)\nSecond, Mr Tom (editor)\nThird Author, Lady"], contributor: ["Doe, Jane (illustrator)\nJoe, G.I."], doi: 'mpub.111111111.blah') }
    let(:file1) { create(:file_set, creator: ["Blerg, Mr (editor)\nElse, Someone (illustrator)"], contributor: ["Brushes, Paint (illustrator)\nJane, G.I."], doi: 'mpub.222222222.blah') }
    let(:file2) { create(:file_set) }
    let(:file3) { create(:file_set) }
    let(:file4) { create(:file_set, title: file4_title) }
    let(:file4_title) { ["Blah-de-blah-blah's Photo & an _\"Italicized, Quoted Title\"_"] }
    let(:file4_title_csv_encoded) { "\"Blah-de-blah-blah's Photo & an _\"\"Italicized, Quoted Title\"\"_\"" }

    let(:original_file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'kitty.tif'))
        f.original_name = 'kitty.tif'
        f.mime_type = 'image/tiff'
        f.file_size = File.size(File.join(fixture_path, 'kitty.tif'))
        f.width = 200
        f.height = 150
      end
    end

    let(:original_file_non_ascii) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'csv', 'import_sections', 'ファイル.txt'))
        f.original_name = 'ファイル.txt'
        f.mime_type = 'application/txt'
        f.file_size = File.size(File.join(fixture_path, 'csv', 'import_sections', 'ファイル.txt'))
      end
    end

    let(:file3_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(file3.to_solr), nil) }

    let(:expected) do
      <<~eos
        NOID,File Name,Link,Embed Code,Date Uploaded,Date Modified,Title,Resource Type,External Resource URL,Caption,Alternative Text,Rightsholder,Copyright Status,Open Access?,Funder,Funder Display,Allow Fullscreen Display?,Allow Download?,Rights Granted,CC License,Permissions Expiration Date,After Expiration: Allow Display?,After Expiration: Allow Download?,Credit Line,Holding Contact,Exclusive to Fulcrum,Identifier(s),Content Type,Creator(s),Additional Creator(s),Creator Display,Sort Date,Display Date,Description,Content Warning,Content Warning Information,Publisher,Subject,ISBN(s),Buy Book URL,Pub Year,Pub Location,Series,Edition Name,Previous Edition,Next Edition,Keywords,Section Titles,Section,Language,Transcript,Translation,DOI,Handle,Closed Captions,Visual Descriptions,Tombstone?,Tombstone Message,Volume,OCLC Work Identifier,Copyright Year,Award(s),Article Title,Article Creator(s),Article Permalink,Article Volume,Article Issue,Article Display Date,Press,Published?,Date Published on Fulcrum,Representative Kind
        instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder,instruction placeholder
        #{file1.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file1)}"")",,#{file1.date_uploaded},#{file1.date_modified},#{file1.title.first},#{file1.resource_type.first},,,,,,,,,,,,,,,,,,,,,"Blerg, Mr (editor); Else, Someone (illustrator)","Brushes, Paint (illustrator); Jane, G.I.",,#{file1.sort_date},,,,,,,,,,,,,,,,,,,,,https://doi.org/mpub.222222222.blah,,,,,,,,,,,,,,,,,false,,
        #{file2.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file2)}"")",,#{file2.date_uploaded},#{file2.date_modified},#{file2.title.first},#{file2.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,,#{file2.sort_date},,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,false,,cover
        #{file3.id},kitty.tif,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file3)}"")","#{file3_presenter.embed_code}",#{file3.date_uploaded},#{file3.date_modified},#{file3.title.first},#{file3.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,,#{file3.sort_date},,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,false,,epub
        #{file4.id},ファイル.txt,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file4)}"")",,#{file4.date_uploaded},#{file4.date_modified},#{file4_title_csv_encoded},#{file4.resource_type.first},,,,,,,,,,,,,,,,,,,,,,,,#{file4.sort_date},,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,false,,
        #{monograph.id},://:MONOGRAPH://:,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_monograph_url(monograph)}"")",,#{monograph.date_uploaded},#{monograph.date_modified},#{monograph.title.first},,,,,,,,,,,,,,,,,,,,,,"First, Ms Joan (editor); Second, Mr Tom (editor); Third Author, Lady","Doe, Jane (illustrator); Joe, G.I.",,,,,,,,,,,,,,,,,,,://:MONOGRAPH://:,,,,https://doi.org/mpub.111111111.blah,,,,,,,,,,,,,,,,#{monograph.press},false,,
      eos
    end

    before do
      file3.original_file = original_file
      file3.save!
      file4.original_file = original_file_non_ascii
      file4.save!
      # Upgrade to ruby 2.7.3 weirdness, HELIO-3950
      file4.original_file.original_name.force_encoding("UTF-8")
      file4.save!
      monograph.ordered_members << file1
      monograph.ordered_members << file2
      monograph.ordered_members << file3
      monograph.ordered_members << file4
      monograph.representative_id = file2.id
      monograph.thumbnail_id = file2.id
      monograph.save!
      FeaturedRepresentative.create!(work_id: monograph.id, file_set_id: file3.id, kind: 'epub')
    end

    after { FeaturedRepresentative.destroy_all }

    it do
      actual = subject
      expect(actual.empty?).to be false
      expect(actual.dup.force_encoding("UTF-8")).to match expected.dup.force_encoding("UTF-8")
    end
  end

  describe '#monograph_row' do
    # for ease of comparison with output (and specs above) we'll pass the generated array through CSV.generate_line
    subject { CSV.generate_line(described_class.new(monograph.id, rows).monograph_row) }

    let(:monograph) { create(:monograph, creator: ["First, Ms Joan (editor)\nSecond, Mr Tom (editor)\nThird Author, Lady"], contributor: ["Doe, Jane (illustrator)\nJoe, G.I."], doi: 'mpub.111111111.blah') }

    context 'when there is no `columns` parameter in exporter initializer (default)' do
      let(:rows) { nil }
      let(:expected) do
        <<~eos
          #{monograph.id},://:MONOGRAPH://:,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_monograph_url(monograph)}"")",,#{monograph.date_uploaded},#{monograph.date_modified},#{monograph.title.first},,,,,,,,,,,,,,,,,,,,,,"First, Ms Joan (editor); Second, Mr Tom (editor); Third Author, Lady","Doe, Jane (illustrator); Joe, G.I.",,,,,,,,,,,,,,,,,,,://:MONOGRAPH://:,,,,https://doi.org/mpub.111111111.blah,,,,,,,,,,,,,,,,#{monograph.press},false,,
        eos
      end

      it 'outputs a row containing all fields' do
        actual = subject
        expect(actual.empty?).to be false
        expect(actual).to match expected
      end
    end

    context 'when there is a `columns` parameter of `:monograph` in exporter initializer' do
      let(:rows) { :monograph }
      let(:expected) do
        <<~eos
          #{monograph.id},"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_monograph_url(monograph)}"")",#{monograph.date_uploaded},#{monograph.date_modified},#{monograph.title.first},,,,,,,,"First, Ms Joan (editor); Second, Mr Tom (editor); Third Author, Lady","Doe, Jane (illustrator); Joe, G.I.",,,,,,,,,,,,,,,,,,https://doi.org/mpub.111111111.blah,,,,,,,,#{monograph.press},false,
        eos
      end

      it 'outputs a row containing only Monograph and universal fields' do
        actual = subject
        expect(actual.empty?).to be false
        expect(actual).to match expected
      end
    end
  end

  describe 'FileSet creator, contributor and article_creator' do
    # for ease of comparison with output (and specs above) we'll pass the generated array through CSV.generate_line
    subject { CSV.generate_line(described_class.new(nil).metadata_row(file_set)) }

    let(:file_set) { create(:file_set, creator: ["First, Ms Joan (editor)\nSecond, Mr Tom (editor)\nThird Author, Lady"], contributor: ["Doe, Jane (illustrator)\nJoe, G.I."], article_creator: ["Bob, Billy\nO'Lantern, Jack\r\nDoe, Jane"]) }
    let(:expected) do
      <<~eos
        #{file_set.id},,"=HYPERLINK(""#{Rails.application.routes.url_helpers.hyrax_file_set_url(file_set)}"")",,#{file_set.date_uploaded},#{file_set.date_modified},#{file_set.title.first},#{file_set.resource_type.first},,,,,,,,,,,,,,,,,,,,,"First, Ms Joan (editor); Second, Mr Tom (editor); Third Author, Lady","Doe, Jane (illustrator); Joe, G.I.",,#{file_set.sort_date},,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"Bob, Billy; O'Lantern, Jack; Doe, Jane",,,,,,false,
      eos
    end

    it 'outputs a row containing the correct field metadata in semi-colon-separated, "Fulcrum CSV"-style format' do
      actual = subject
      expect(actual.empty?).to be false
      expect(actual).to match expected
    end
  end
end
