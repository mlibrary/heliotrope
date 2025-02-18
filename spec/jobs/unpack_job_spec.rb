# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnpackJob, type: :job do
  describe 'perform' do
    context 'with a missing original_file' do
      let(:no_file_file_set) { create(:file_set) }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

      it 'raises Resque::Job::DontPerform, which is discarded, and does not create a derivatives directory' do
        expect(described_class.perform_now(no_file_file_set.id, 'epub').class).to eq(Resque::Job::DontPerform)
        expect(Dir.exist?(File.dirname(UnpackService.root_path_from_noid(no_file_file_set.id, 'epub')))).to be false
      end
    end

    context 'with a reflowable epub' do
      let(:monograph) { create(:monograph) }
      let(:reflowable_epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let(:root_path) { UnpackService.root_path_from_noid(reflowable_epub.id, 'epub') }
      let(:chapters_dir) { UnpackService.root_path_from_noid(reflowable_epub.id, 'epub_chapters') }

      before do
        monograph.ordered_members << reflowable_epub
        monograph.save!
        reflowable_epub.save!
        # the `find` and `parent` stubs are necessary for the `update_index` stub to work
        allow(FileSet).to receive(:find).with(reflowable_epub.id).and_return(reflowable_epub)
        allow(reflowable_epub).to receive(:parent).and_return(monograph)
        allow(monograph).to receive(:update_index)
      end

      it "unzips the epub, caches the ToC, creates the search database and doesn't make chapter files derivatives" do
        # check that we're reindexing to get the ToC and accessibility metadata on the parent Monograph's Solr doc
        expect(monograph).to receive(:update_index)
        described_class.perform_now(reflowable_epub.id, 'epub')
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: reflowable_epub.id).toc).length).to eq 3
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: reflowable_epub.id).toc)[0]['title']).to eq 'Damage report!'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: reflowable_epub.id).toc)[0]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: reflowable_epub.id).toc)[0]['cfi']).to eq '/6/2[Chapter01]!/4/1:0'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: reflowable_epub.id).toc)[0]['downloadable?']).to eq false
        expect(File.exist?(File.join(root_path, reflowable_epub.id + '.db'))).to be true
        expect(Dir.exist?(chapters_dir)).to be false
      end
    end

    context 'with a fixed-layout epub' do
      let(:monograph) { create(:monograph) }
      let(:fixed_layout_epub) { create(:file_set, content: File.open(File.join(fixture_path, 'the-whale.epub'))) }
      let(:root_path) { UnpackService.root_path_from_noid(fixed_layout_epub.id, 'epub') }
      let(:chapters_dir) { UnpackService.root_path_from_noid(fixed_layout_epub.id, 'epub_chapters') }

      before do
        monograph.ordered_members << fixed_layout_epub
        monograph.save!
        fixed_layout_epub.save!
        # the `find` and `parent` stubs are necessary for the `update_index` stub to work
        allow(FileSet).to receive(:find).with(fixed_layout_epub.id).and_return(fixed_layout_epub)
        allow(fixed_layout_epub).to receive(:parent).and_return(monograph)
        allow(monograph).to receive(:update_index)
      end

      it 'unzips the epub, caches the ToC, creates the search database and makes the chapter files derivatives' do
        # check that we're reindexing to get the ToC and accessibility metadata on the parent Monograph's Solr doc
        expect(monograph).to receive(:update_index)
        described_class.perform_now(fixed_layout_epub.id, 'epub')
        expect(File.exist?(File.join(root_path, fixed_layout_epub.id + '.db'))).to be true
        expect(Dir.exist?(chapters_dir)).to be true
        expect(Dir.glob(File.join(chapters_dir, '**', '*')).select { |file| File.file?(file) }.count).to eq 14
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: fixed_layout_epub.id).toc).length).to eq 14
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: fixed_layout_epub.id).toc)[0]['title']).to eq 'Frontmatter'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: fixed_layout_epub.id).toc)[0]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: fixed_layout_epub.id).toc)[0]['cfi']).to eq '/6/2[xhtml00000001]!/4/1:0'
        # As far as EbooksTableOfContents is concerned, if the chapters exist, they are downloadable? = true
        # The application itself (see views/monograph_catalog/_index_epub_toc.html.erb) will use...
        # the EbookIntervalDownloadOperation policy in combination with this to show or hide download links
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: fixed_layout_epub.id).toc)[0]['downloadable?']).to eq true
      end
    end

    context 'with a webgl' do
      let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
      let(:root_path) { UnpackService.root_path_from_noid(webgl.id, 'webgl') }

      it 'unzips the webgl' do
        described_class.perform_now(webgl.id, 'webgl')
        expect(File.exist?(File.join(root_path, 'Build', 'blah.loader.js'))).to be true
      end
    end

    context 'with a pdf_ebook' do
      let(:monograph) { create(:monograph) }
      let(:pdf_ebook) { create(:file_set, content: File.open(File.join(fixture_path, 'lorum_ipsum_toc.pdf'))) }
      let(:root_path) { UnpackService.root_path_from_noid(pdf_ebook.id, 'pdf_ebook') }
      let(:chapters_dir) { UnpackService.root_path_from_noid(pdf_ebook.id, 'pdf_ebook_chapters') }

      before do
        monograph.ordered_members << pdf_ebook
        monograph.save!
        pdf_ebook.save!
      end

      it 'makes the pdf_ebook, caches the ToC and makes the chapter files derivatives' do
        described_class.perform_now(pdf_ebook.id, 'pdf_ebook')
        expect(File.exist?("#{root_path}.pdf")).to be true
        expect(Dir.exist?(chapters_dir)).to be true
        expect(Dir.glob(File.join(chapters_dir, '**', '*')).select { |file| File.file?(file) }.count).to eq 7
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc).length).to eq 9
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]['title']).to eq 'The standard Lorem Ipsum passage, used since the 1500s'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]['cfi']).to eq 'page=3'
        # As far as EbooksTableOfContents is concerned, if the chapters exist, they are downloadable? = true
        # The application itself (see views/monograph_catalog/_index_epub_toc.html.erb) will use...
        # the EbookIntervalDownloadOperation policy in combination with this to show or hide download links
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]['downloadable?']).to eq true

        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[1]['title']).to eq 'Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[1]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[1]['cfi']).to eq 'page=4'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[1]['downloadable?']).to eq true

        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[2]['title']).to eq 'Yet Another Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[2]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[2]['cfi']).to eq 'page=4'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[2]['downloadable?']).to eq true

        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[3]['title']).to eq 'A Sub-section of Yet Another Section of "de Finibus Bonorum et Malorum"'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[3]['level']).to eq 2
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[3]['cfi']).to eq 'page=4'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[3]['downloadable?']).to eq true

        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[4]['title']).to eq '1914 translation by H. Rackham'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[4]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[4]['cfi']).to eq 'page=5'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[4]['downloadable?']).to eq true

        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[5]['title']).to eq 'Section 1.10.33 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[5]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[5]['cfi']).to eq 'page=6'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[5]['downloadable?']).to eq true

        # note that this is a ToC entry (bookmark) that lacks a destination. We see these in production content, especially backlist stuff. Presumably in error.
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[6]['title']).to eq 'No Destination 1'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[6]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[6]['cfi']).to eq 'page='
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[6]['downloadable?']).to eq false

        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[7]['title']).to eq '1914 translation by H. Rackham again'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[7]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[7]['cfi']).to eq 'page=7'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[7]['downloadable?']).to eq true

        # note that this is a ToC entry (bookmark) that lacks a destination. We see these in production content, especially backlist stuff. Presumably in error.
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[8]['title']).to eq 'No Destination 2'
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[8]['level']).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[8]['cfi']).to eq 'page='
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[8]['downloadable?']).to eq false
      end

      context "missing PDF chapter files for PDFs with layered ToC's" do
        before do
          # this line is weirdly necessary https://github.com/chefspec/chefspec/issues/766#issuecomment-396631456
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(File.join(UnpackService.root_path_from_noid(pdf_ebook.id, 'pdf_ebook_chapters'), '3.pdf')).and_return(false)
        end

        it 'checks the existence of the correct file name based on the "overall index" of the nested chapter' do
          described_class.perform_now(pdf_ebook.id, 'pdf_ebook')
          # 3.pdf is the first entry in a subsection (depth higher than 1), with index == 0 in its section,...
          # overall_index == 3. Before overall_index was added for PDFEbook::Interval.downloadable? this check would...
          # erroneously always be against `<index within current depth>.pdf`, i.e. 0.pdf in this case.
          expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[3]['downloadable?']).to eq false
        end
      end
    end

    context 'with an epub and pre-existing webgl' do
      let(:monograph) { create(:monograph) }
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let!(:fre) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
      let!(:frw) { create(:featured_representative, work_id: monograph.id, file_set_id: '123456789', kind: 'webgl') }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

      before do
        monograph.ordered_members << epub
        monograph.save!
        epub.save!
      end

      after { FeaturedRepresentative.destroy_all }

      it 'creates the epub-webgl map' do
        described_class.perform_now(epub.id, 'epub')
        expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be true
      end
    end

    context 'with a pre-existing epub' do
      let(:monograph) { create(:monograph) }
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }

      before do
        monograph.ordered_members << epub
        monograph.save!
        epub.save!
        # we need the epub already unpacked in order to store the epub-webgl map file
        described_class.perform_now(epub.id, 'epub')
      end

      after { FeaturedRepresentative.destroy_all }

      context 'adding a webgl' do
        let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
        let!(:fre) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
        let!(:frw) { create(:featured_representative, work_id: monograph.id, file_set_id: webgl.id, kind: 'webgl') }
        # The root_path of the epub, not the webgl is used to test
        let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

        it 'creates the epub-webgl map' do
          expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be false
          described_class.perform_now(webgl.id, 'webgl')
          expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be true
        end
      end
    end

    context 'with a map' do
      let(:map) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-map.zip'))) }
      let(:root_path) { UnpackService.root_path_from_noid(map.id, 'interactive_map') }

      after { FileUtils.rm_rf(root_path) }

      it 'unzips the map' do
        described_class.perform_now(map.id, 'interactive_map')
        expect(File.exist?(File.join(root_path, 'index.html'))).to be true
      end
    end
  end
end
