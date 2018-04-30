# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Validator do
  describe "with a valid epub" do
    before do
      @id = '999999999'
      @file = './spec/fixtures/fake_epub01.epub'
      EPub::Publication.from(id: @id, file: @file)
    end

    after do
      EPub::Publication.from(@id).purge
    end

    describe "#container" do
      subject { described_class.from(@id) }
      it "has the epub container information" do
        expect(subject.container.name).to eq 'document'
        expect(subject.container.xpath("//rootfile/@full-path").length).to eq 1
      end
    end

    describe "#content_file" do
      context "with a single rendition" do
        subject { described_class.from(@id) }
        it "returns the content file" do
          expect(subject.content_file).to eq 'EPUB/content.opf'
        end
      end
      context "with multiple renditions" do
        before do
          File.open(EPub.path_entry(@id, "META-INF/container.xml"), 'w') do |f|
            f.puts %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
              <rootfiles>
                <rootfile full-path="EPUB/content.opf" media-type="application/oebps-package+xml" rendition:accessMode="textual"/>
                <rootfile full-path="EPUB/not_a_thing.opf" media-type="application/oebps-package+xml" rendition:accessMode="visual"/>
              </rootfiles>
            </container>)
          end
        end
        subject { described_class.from(@id) }
        it "has the correct (always the first) rendition" do
          expect(subject.content_file).to eq 'EPUB/content.opf'
        end
      end
    end

    describe "#content" do
      subject { described_class.from(@id) }
      it "contains epub package information" do
        expect(subject.content.children[0].name).to eq "package"
      end
    end

    describe "#toc" do
      subject { described_class.from(@id) }
      it "contains the epub navigation element" do
        expect(subject.toc.xpath("//body/nav").any?).to be true
      end
    end
  end

  describe "with an invalid epub" do
    before do
      allow(EPub).to receive(:path).with(@id).and_return("")
      allow(EPub.logger).to receive(:info).and_return(true)
    end

    subject { described_class.from(@id) }
    it "is a ValidatorNullObject" do
      is_expected.to be_an_instance_of(EPub::ValidatorNullObject)
      expect(subject.id).to eq 'null_epub'
      expect(subject.container).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.content_file).to be "empty"
      expect(subject.content).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.toc).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.root_path).to be nil
    end
  end
end
