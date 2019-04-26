# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RestfulSolr do
  describe '#url' do
    subject { described_class.url }

    it { is_expected.to eq ActiveFedora.solr_config[:url] }
  end
end
