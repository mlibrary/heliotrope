# frozen_string_literal: true

require 'rails_helper'

describe MonographSearchBuilder do
  let(:search_builder) { described_class.new(context) }
  let(:config) { CatalogController.blacklight_config }
  let(:context) { double('context', blacklight_config: config) }
  let(:solr_params) { { fq: [] } }

  describe "#filter_by_members" do
    context "a monograph with assets" do
      let(:monograph) do
        ::SolrDocument.new(id: 'mono',
                           has_model_ssim: ['Monograph'],
                           # representative_id has a rather different Solr name!
                           hasRelatedMediaFragment_ssim: cover.id,
                           ordered_member_ids_ssim: [cover_noid, file1_noid, file2_noid])
      end

      let(:cover_noid) { 'cover1234' }
      let(:file1_noid) { '111111111' }
      let(:file2_noid) { '222222222' }

      let(:cover) { ::SolrDocument.new(id: cover_noid, has_model_ssim: ['FileSet'], monograph_id_ssim: ['mono'], visibility_ssi: 'open') }
      let(:file1) { ::SolrDocument.new(id: file1_noid, has_model_ssim: ['FileSet'], monograph_id_ssim: ['mono'], visibility_ssi: 'open') }
      let(:file2) { ::SolrDocument.new(id: file2_noid, has_model_ssim: ['FileSet'], monograph_id_ssim: ['mono'], visibility_ssi: 'open') }

      before do
        ActiveFedora::SolrService.add([monograph.to_h, cover.to_h, file1.to_h, file2.to_h])
        ActiveFedora::SolrService.commit
        search_builder.blacklight_params['id'] = "mono"
      end

      context "reprensentative id (cover)" do
        before { search_builder.filter_by_members(solr_params) }

        it "creates a query for the monograph's assets but without the representative_id" do
          expect(solr_params[:fq].first).to match(/^{!terms f=id}#{file1_noid},#{file2_noid}$/)
        end
      end

      FeaturedRepresentative::KINDS.each do |kind|
        context kind do
          before { FeaturedRepresentative.create!(work_id: "mono", file_set_id: file2_noid, kind: kind) }

          it "creates a query for the monograph's assets" do
            search_builder.filter_by_members(solr_params)
            expect(solr_params[:fq].first).to match(/^{!terms f=id}#{file1_noid}$/)
          end
        end
      end

      context 'tombstone' do
        context 'with a valid permissions_expiration_date_ssim date' do
          let(:file2) do
            ::SolrDocument.new(id: file2_noid,
                               has_model_ssim: ['FileSet'],
                               permissions_expiration_date_ssim: Time.now.yesterday.utc.to_s,
                               monograph_id_ssim: ['mono'],
                               visibility_ssi: 'open')
          end

          before do
            ActiveFedora::SolrService.add([file2.to_h])
            ActiveFedora::SolrService.commit
          end

          it "creates a query for the monograph's assets without tombstone" do
            search_builder.filter_by_members(solr_params)
            expect(solr_params[:fq].first).to match(/^{!terms f=id}#{file1_noid}$/)
          end
        end

        context 'with an empty string in permissions_expiration_date_ssim' do
          # This happens sometimes. It shouldn't, and I'm not sure why it does,
          # but some of our data is like this, see HELIO-3748
          let(:file2) do
            ::SolrDocument.new(id: file2_noid,
                               has_model_ssim: ['FileSet'],
                               permissions_expiration_date_ssim: [""], # weird empty string
                               monograph_id_ssim: ['mono'],
                               visibility_ssi: 'open')
          end

          before do
            ActiveFedora::SolrService.add([file2.to_h])
            ActiveFedora::SolrService.commit
          end

          it "creates a query with the correct file_sets/assets" do
            search_builder.filter_by_members(solr_params)
            expect(solr_params[:fq].first).to match(/^{!terms f=id}#{file1_noid},#{file2_noid}$/)
          end
        end

        context "with an invalid date" do
          let(:file2) do
            ::SolrDocument.new(id: file2_noid,
                               has_model_ssim: ['FileSet'],
                               permissions_expiration_date_ssim: ["garbage"],
                               monograph_id_ssim: ['mono'],
                               visibility_ssi: 'open')
          end

          before do
            ActiveFedora::SolrService.add([file2.to_h])
            ActiveFedora::SolrService.commit
          end

          it "creates a query with the correct file_sets/assets" do
            search_builder.filter_by_members(solr_params)
            expect(solr_params[:fq].first).to match(/^{!terms f=id}#{file1_noid},#{file2_noid}$/)
          end
        end
      end
    end

    context "a monograph with no assets" do
      let(:monograph) do
        ::SolrDocument.new(id: 'mono',
                           has_model_ssim: ['Monograph'])
      end

      before do
        ActiveFedora::SolrService.add([monograph.to_h])
        ActiveFedora::SolrService.commit
        search_builder.blacklight_params['id'] = 'mono'
        search_builder.filter_by_members(solr_params)
      end

      it "creates an empty query for the monograph's assets" do
        expect(solr_params[:fq].first).to eq("{!terms f=id}")
      end
    end

    # Maybe this test doesn't belong here... but where to put it?
    # We're testing search, not really the search_builder...
    # For #386
    context "a monograph with file_sets with markdown content" do
      let(:monograph) do
        ::SolrDocument.new(id: 'mono',
                           has_model_ssim: ['Monograph'],
                           # representative_id has a rather different Solr name!
                           hasRelatedMediaFragment_ssim: cover.id,
                           ordered_member_ids_ssim: ["cover", "file1", "file2"])
      end
      let(:cover) { ::SolrDocument.new(id: 'cover', has_model_ssim: ['FileSet'], title_tesim: ["Blue"], description_tesim: ["italic _elephant_"], visibility_ssi: 'open') }
      let(:file1) { ::SolrDocument.new(id: 'file1', has_model_ssim: ['FileSet'], title_tesim: ["Red"], description_tesim: ["bold __spider__"], visibility_ssi: 'open') }
      let(:file2) { ::SolrDocument.new(id: 'file2', has_model_ssim: ['FileSet'], title_tesim: ["Yellow"], description_tesim: ["strikethrough ~~lizard~~"], visibility_ssi: 'open') }

      before do
        ActiveFedora::SolrService.add([monograph.to_h, cover.to_h, file1.to_h, file2.to_h])
        ActiveFedora::SolrService.commit
      end

      it "recieves the correct file_set after searching for italic" do
        doc = ActiveFedora::SolrService.query("{!terms f=description_tesim}elephant", rows: 10_000).first
        expect(doc[:title_tesim]).to eq(["Blue"])
      end

      it "recieves the correct result after searching for bold" do
        doc = ActiveFedora::SolrService.query("{!terms f=description_tesim}spider", rows: 10_000).first
        expect(doc[:title_tesim]).to eq(["Red"])
      end

      it "recieves the correct result after searching for strikethrough" do
        # solr doesn't need any changes in solr/config/schema.xml for strikethrough.
        # It just "does the right thing". Should test it anyway I guess.
        doc = ActiveFedora::SolrService.query("{!terms f=description_tesim}lizard", rows: 10_000).first
        expect(doc[:title_tesim]).to eq(["Yellow"])
      end
    end
  end
end
