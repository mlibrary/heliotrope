require 'rails_helper'

describe SearchBuilder do
  let(:processor_chain) { [:filter_models] }
  let(:ability) { double('ability') }
  let(:context) { double('context') }
  let(:user) { double('user') }
  let(:solr_params) { { fq: [] } }

  subject { described_class.new(processor_chain, context) }
  describe '#filter_models' do
    context "with default work types" do
      before { subject.filter_models(solr_params) }

      it 'limits query to collection and generic work' do
        expect(solr_params[:fq].first).to match(/{!raw f=has_model_ssim}Monograph.*OR.*{!raw f=has_model_ssim}Collection/)
        expect(solr_params[:fq].first).not_to match(/{!raw f=has_model_ssim}Section/)
      end
    end
  end
end
