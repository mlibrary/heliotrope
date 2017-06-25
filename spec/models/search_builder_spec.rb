# frozen_string_literal: true

require 'rails_helper'

# Hyrax Example
#
# describe SearchBuilder do
#   let(:user_params) { Hash.new }
#   let(:blacklight_config) { Blacklight::Configuration.new }
#   let(:scope) { double blacklight_config: blacklight_config }
#   subject(:search_builder) { described_class.new scope }
#
#   # describe "my custom step" do
#   #   subject(:query_parameters) do
#   #     search_builder.with(user_params).processed_parameters
#   #   end
#   #
#   #   it "adds my custom data" do
#   #     expect(query_parameters).to include :custom_data
#   #   end
#   # end
# end

describe SearchBuilder do
  let(:ability) { double('ability') }
  let(:config) { CatalogController.blacklight_config }
  let(:context) { double('context', blacklight_config: config) }
  let(:user) { double('user') }
  let(:solr_params) { { fq: [] } }
  let(:search_builder) { described_class.new(context) }

  describe '#filter_models' do
    context "with default work types" do
      before { search_builder.filter_models(solr_params) }

      it 'limits query to collection and generic work' do
        expect(solr_params[:fq].first).to match(/{!terms f=has_model_ssim}Monograph,Asset,Collection/)
      end
    end
  end

  describe "searching" do
    subject do
      search_builder.where('fish').query
    end

    it "searches the required fields" do
      allow(context).to receive(:current_ability) { Ability.new(nil) }
      expect(subject['qf']).to match %r{\btitle_tesim\b}
      expect(subject['qf']).to match %r{\bcreator_full_name_tesim\b}
      expect(subject['qf']).to match %r{\bsubject_tesim\b}
    end

    it "facets the required fields" do
      allow(context).to receive(:current_ability) { Ability.new(nil) }
      expect(subject['facet.field']).to include 'subject_sim'
    end
  end
end
