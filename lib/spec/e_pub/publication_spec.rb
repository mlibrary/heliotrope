# frozen_string_literal: true

require 'byebug'

RSpec.describe EPub::Publication do
  describe "without a test epub" do
    let(:noid) { 'validnoid' }
    let(:non_noid) { 'invalidnoid' }

    before do
      allow(EPubsService).to receive(:open).with(noid).and_return(nil)
      allow(EPub::Cache).to receive(:cached?).with(noid).and_return(true)
    end

    # Class Methods

    describe '#clear_cache' do
      it { expect(described_class).to respond_to(:clear_cache) }
    end

    describe '#from' do
      subject { described_class.from(data) }

      context 'null object' do
        context 'non hash' do
          context 'nil' do
            let(:data) { nil }

            it 'returns an instance of PublicationNullObject' do
              is_expected.to be_an_instance_of(EPub::PublicationNullObject)
            end
          end
          context 'non-noid' do
            let(:data) { non_noid }

            it 'returns an instance of PublicationNullObject' do
              is_expected.to be_an_instance_of(EPub::PublicationNullObject)
            end
          end
        end
        context 'hash' do
          context 'empty' do
            let(:data) { {} }

            it 'returns an instance of PublicationNullObject' do
              is_expected.to be_an_instance_of(EPub::PublicationNullObject)
            end
          end
          context 'nil' do
            let(:data) { { id: nil } }

            it 'returns an instance of PublicationNullObject' do
              is_expected.to be_an_instance_of(EPub::PublicationNullObject)
            end
          end
          context 'non-noid' do
            let(:data) { { id: non_noid } }

            it 'returns an instance of PublicationNullObject' do
              is_expected.to be_an_instance_of(EPub::PublicationNullObject)
            end
          end
        end
      end

      context 'publication' do
        context 'non hash' do
          let(:data) { noid }

          it 'returns an instance of a Publication' do
            is_expected.to be_an_instance_of(described_class)
          end
        end
        context 'hash' do
          let(:data) { { id: noid } }

          it 'returns an instance of a Publication' do
            is_expected.to be_an_instance_of(described_class)
          end
        end
      end
    end

    describe '#new' do
      it 'private_class_method' do
        expect { is_expected }.to raise_error(NoMethodError)
      end
    end

    describe '#null_object' do
      subject { described_class.null_object }

      it 'returns an instance of PublicationNullObject' do
        is_expected.to be_an_instance_of(EPub::PublicationNullObject)
      end
    end

    # Instance Methods

    describe '#id' do
      subject { described_class.from(noid).id }
      it 'returns noid' do
        is_expected.to eq noid
      end
    end

    describe '#presenter' do
      subject { described_class.from(noid).presenter }

      it 'returns an publication presenter' do
        is_expected.to be_an_instance_of(EPub::PublicationPresenter)
        expect(subject.id).to eq noid
      end
    end

    describe '#purge' do
      subject { described_class.from(noid).purge }
      it { is_expected.to be nil }
    end

    describe '#read' do
      subject { described_class.from(noid).read(file_entry) }

      let(:file_entry) { double("file_entry") }
      let(:text) { double("text") }

      before do
        allow(EPubsService).to receive(:read).with(noid, file_entry).and_return(text)
      end

      context 'epubs service returns text' do
        it 'returns text' do
          is_expected.to eq text
        end
      end

      context 'epubs service raises standard error' do
        before do
          allow(EPubsService).to receive(:read).with(noid, file_entry).and_raise(StandardError)
          @message = 'message'
          allow(EPub.logger).to receive(:info).with(any_args) { |value| @message = value }
        end

        it 'returns null object read' do
          is_expected.not_to eq text
          is_expected.to eq described_class.null_object.read(file_entry)
          expect(@message).not_to eq 'message'
          expect(@message).to eq 'Publication.read(#[Double "file_entry"])  in publication validnoid raised StandardError'
        end
      end
    end

    describe '#search' do
      subject { described_class.from(noid).search(query) }

      let(:e_pubs_search_service) { double("e_pubs_search_service") }
      let(:query) { double("query") }
      let(:results) { double("results") }

      before do
        allow(EPubsSearchService).to receive(:new).with(noid).and_return(e_pubs_search_service)
        allow(e_pubs_search_service).to receive(:search).with(query).and_return(results)
      end

      context 'epubs search service returns results' do
        it 'returns results' do
          is_expected.to eq results
        end
      end

      context 'epubs search service raises standard error' do
        before do
          allow(e_pubs_search_service).to receive(:search).with(query).and_raise(StandardError)
          @message = 'message'
          allow(EPub.logger).to receive(:info).with(any_args) { |value| @message = value }
        end

        it 'returns null object query' do
          is_expected.not_to eq results
          is_expected.to eq described_class.null_object.search(query)
          expect(@message).not_to eq 'message'
          expect(@message).to eq 'Publication.search(#[Double "query"]) in publication validnoid raised StandardError at: e.backtrace[0]'
        end
      end
    end
  end

  describe "with a test epub" do
    let(:id) { '999999999' }

    before do
      FileUtils.mkdir_p "../tmp/epubs" unless Dir.exist? "../tmp/epubs"
      FileUtils.cp_r "spec/fixtures/fake_epub01_unpacked", "../tmp/epubs/#{id}"
      allow(EPubsService).to receive(:epub_path).and_return("../tmp/epubs/#{id}")
      allow(FactoryService).to receive(:e_pub_publication_from).with(id).and_return(described_class.from(id: id, epub: nil))
    end

    after do
      FileUtils.rm_rf "../tmp/epubs/#{id}" if Dir.exist?("../tmp/epubs/#{id}")
    end

    describe "#container" do
      subject { FactoryService.e_pub_publication(id) }
      it "returns the container.opf file" do
        expect(subject.container.xpath("//rootfile/@full-path").text).to eq 'EPUB/content.opf'
      end
    end

    describe "#content_file" do
      subject { FactoryService.e_pub_publication(id) }
      it "returns the content file" do
        expect(subject.content_file).to eq 'EPUB/content.opf'
      end
    end

    describe "#content_dir" do
      subject { FactoryService.e_pub_publication(id) }
      it "returns the content directory" do
        expect(subject.content_dir).to eq 'EPUB'
      end
    end

    describe "#content" do
      subject { FactoryService.e_pub_publication(id) }
      it "contains epub package information" do
        expect(subject.content.children[0].name).to eq "package"
      end
    end

    describe "#epub_path" do
      subject { FactoryService.e_pub_publication(id) }
      it "returns the epub's path" do
        expect(subject.epub_path).to eq "../tmp/epubs/#{id}"
      end
    end

    describe "#toc" do
      subject { FactoryService.e_pub_publication(id) }
      it "contains the epub navigation element" do
        expect(subject.toc.xpath("//body/nav").any?).to be true
      end
    end

    describe "#chapters" do
      subject { FactoryService.e_pub_publication(id) }
      it "has 3 chapters" do
        expect(subject.chapters.count).to be 3
      end

      describe "the first chapter" do
        # It's a little wrong to test this here, but Publication has the logic
        # that populates the Chapter object, so it's here. For now.
        subject { FactoryService.e_pub_publication(id).chapters[0] }
        it "has the id of" do
          expect(subject.chapter_id).to eq "Chapter01"
        end
        it "has the href of" do
          expect(subject.chapter_href).to eq "xhtml/Chapter01.xhtml"
        end
        it "has the title of" do
          expect(subject.title).to eq 'Damage report!'
        end
        it "has the base_cfi of" do
          expect(subject.base_cfi).to eq '/6/2[Chapter01]!'
        end
        it "has the chapter doc" do
          expect(subject.doc.name).to eq 'document'
          expect(subject.doc.xpath("//p")[2].text).to eq "Computer, belay that order"
        end
      end
    end
  end
end
