# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Validator do
  let(:id) { '999999999' }

  describe "with a valid epub" do
    before do
      FileUtils.mkdir_p "../tmp/epubs" unless Dir.exist? "../tmp/epubs"
      FileUtils.cp_r "spec/fixtures/fake_epub01_unpacked", "../tmp/epubs/#{id}"
      allow(EPubsService).to receive(:epub_path).and_return("../tmp/epubs/#{id}")
    end

    after do
      FileUtils.rm_rf "../tmp/epubs/#{id}" if Dir.exist?("../tmp/epubs/#{id}")
    end

    describe "#container" do
      subject { described_class.from(id) }
      it "has the epub container information" do
        expect(subject.container.name).to eq 'document'
        expect(subject.container.xpath("//rootfile/@full-path").length).to eq 1
      end
    end

    describe "#content_file" do
      subject { described_class.from(id) }
      it "returns the content file" do
        expect(subject.content_file).to eq 'EPUB/content.opf'
      end
    end

    describe "#content" do
      subject { described_class.from(id) }
      it "contains epub package information" do
        expect(subject.content.children[0].name).to eq "package"
      end
    end

    describe "#toc" do
      subject { described_class.from(id) }
      it "contains the epub navigation element" do
        expect(subject.toc.xpath("//body/nav").any?).to be true
      end
    end
  end

  describe "with an invalid epub" do
    before do
      allow(EPubsService).to receive(:epub_path).and_return("")
      allow(EPub.logger).to receive(:info).and_return(true)
    end

    subject { described_class.from(id) }
    it "is a ValidatorNullObject" do
      is_expected.to be_an_instance_of(EPub::ValidatorNullObject)
    end
  end
end
