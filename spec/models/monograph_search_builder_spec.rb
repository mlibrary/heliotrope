require 'rails_helper'

describe MonographSearchBuilder do
  let(:monograph) { create(:monograph) }
  let(:section) { create(:section) }
  let(:file1) { create(:file_set) }
  let(:file2) { create(:file_set) }
  let(:config) { CatalogController.blacklight_config }
  let(:context) { double('context', blacklight_config: config) }
  let(:solr_params) { { fq: [] } }
  let(:search_builder) { described_class.new(context) }

  before do
    monograph.ordered_members << file1
    section.ordered_members << file2
    section.save!
    monograph.ordered_members << section
    monograph.save!
  end

  describe "#filter_by_members" do
    before {
      search_builder.blacklight_params['id'] = monograph.id
      search_builder.filter_by_members(solr_params)
    }
    it "creates a query for the monograph's assets" do
      expect(solr_params[:fq].first).to match(/{!terms f=id}#{file1.id},#{file2.id}/)
    end
  end
end
