require 'rails_helper'

describe MonographSearchBuilder do
  let(:config) { CatalogController.blacklight_config }
  let(:context) { double('context', blacklight_config: config) }
  let(:solr_params) { { fq: [] } }
  let(:search_builder) { described_class.new(context) }

  describe "#filter_by_members" do
    context "a monograph with assets" do
      let(:monograph) { create(:monograph, representative_id: cover.id) }
      let(:section) { create(:section) }
      let(:cover) { create(:file_set) }
      let(:file1) { create(:file_set) }
      let(:file2) { create(:file_set) }

      before do
        monograph.ordered_members << cover
        monograph.ordered_members << file1
        section.ordered_members << file2
        section.save!
        monograph.ordered_members << section
        monograph.save!
        search_builder.blacklight_params['id'] = monograph.id
        search_builder.filter_by_members(solr_params)
      end
      it "creates a query for the monograph's assets but without the representative_id" do
        expect(solr_params[:fq].first).to match(/{!terms f=id}#{file1.id},#{file2.id}/)
      end
    end

    context "a monograph with no assets" do
      let(:empty_monograph) { create(:monograph) }
      before do
        search_builder.blacklight_params['id'] = empty_monograph.id
        search_builder.filter_by_members(solr_params)
      end
      it "creates an empty query for the monograph's assets" do
        expect(solr_params[:fq].first).to eq("{!terms f=id}")
      end
    end
  end
end
