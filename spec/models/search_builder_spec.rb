# frozen_string_literal: true

require 'rails_helper'

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
        expect(solr_params[:fq].first).to match(/{!terms f=has_model_ssim}Monograph,Score,Collection/)
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

  context 'sort field' do
    let(:default_sort_field) { double('default_sort_field') }

    before { allow(config).to receive(:default_sort_field).and_return(default_sort_field) }

    describe '#default_sort_field' do
      subject { search_builder.default_sort_field }

      it { is_expected.to be default_sort_field }
    end

    describe "#sort" do
      subject { search_builder.sort }

      let(:field) { double('field') }

      before { allow(default_sort_field).to receive(:sort).and_return(field) }

      it { is_expected.to be field }

      context 'param sort' do
        let(:blacklight_params) { { sort: param_field } }
        let(:param_field) { double('param_field') }

        before { allow(search_builder).to receive(:blacklight_params).and_return(blacklight_params) }

        it { is_expected.to be param_field }
      end
    end
  end
end
