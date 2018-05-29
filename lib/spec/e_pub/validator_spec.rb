# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Validator do
  describe "with a valid epub" do
    before do
      @noid = '999999992'
      @root_path = UnpackHelper.noid_to_root_path(@noid, 'epub')
      @file = './spec/fixtures/fake_epub01.epub'
      UnpackHelper.unpack_epub(@noid, @root_path, @file)
      allow(EPub.logger).to receive(:info).and_return(nil)
    end

    after do
      FileUtils.rm_rf(Dir[File.join('./tmp', 'rspec_derivatives')])
    end

    describe "#container" do
      subject { described_class.from_directory(@root_path) }
      it "has the epub container information" do
        expect(subject.container.name).to eq 'document'
        expect(subject.container.xpath("//rootfile/@full-path").length).to eq 1
      end
    end

    describe "#content_file" do
      context "with a single rendition" do
        subject { described_class.from_directory(@root_path) }
        it "returns the content file" do
          expect(subject.content_file).to eq 'EPUB/content.opf'
        end
      end
      context "with multiple renditions" do
        # NOTE: we're emulating .remove_namespaces! here.
        # TODO: probably stop using .remove_namespaces!
        before do
          File.open(File.join(@root_path, "META-INF/container.xml"), 'w') do |f|
            f.puts %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
              <rootfiles>
                <rootfile full-path="EPUB/content.opf"
                          media-type="application/oebps-package+xml"
                          accessMode="visual"
                          label="Text"/>
                <rootfile full-path="EPUB/content_page_image.opf"
                          media-type="application/oebps-package+xml"
                          accessMode="visual"
                          label="Page Scan"/>
              </rootfiles>
            </container>)
          end
        end
        subject { described_class.from_directory(@root_path) }
        it "has the correct OCR rendition" do
          expect(subject.content_file).to eq 'EPUB/content.opf'
        end
        it "has multi_rendition == 'yes'" do
          expect(subject.multi_rendition).to eq 'yes'
        end
      end
    end

    describe "#content" do
      subject { described_class.from_directory(@root_path) }
      it "contains epub package information" do
        expect(subject.content.children[0].name).to eq "package"
      end
    end

    describe "#toc" do
      subject { described_class.from_directory(@root_path) }
      it "contains the epub navigation element" do
        expect(subject.toc.xpath("//body/nav").any?).to be true
      end
    end
  end

  describe "with an invalid epub" do
    before do
      allow(EPub.logger).to receive(:info).and_return(true)
    end

    subject { described_class.from_directory("invalid_root_path") }

    it "is a ValidatorNullObject" do
      is_expected.to be_an_instance_of(EPub::ValidatorNullObject)
      expect(subject.id).to eq 'null_epub'
      expect(subject.container).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.content_file).to be "empty"
      expect(subject.content).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.toc).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.root_path).to be "root_path"
      expect(subject.multi_rendition).to be "no"
    end
  end
end
