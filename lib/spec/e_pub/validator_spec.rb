# frozen_string_literal: true

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
      subject { described_class.from_directory(@root_path) }

      it "returns the content file" do
        expect(subject.content_file).to eq 'EPUB/content.opf'
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
    subject { described_class.from_directory("invalid_root_path") }

    before do
      allow(EPub.logger).to receive(:info).and_return(true)
    end

    it "is a ValidatorNullObject" do
      is_expected.to be_an_instance_of(EPub::ValidatorNullObject)
      expect(subject.id).to eq 'null_epub'
      expect(subject.container).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.content_file).to be "empty"
      expect(subject.content).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.toc).to be_an_instance_of(Nokogiri::XML::Document)
      expect(subject.root_path).to be "root_path"
    end
  end
end
