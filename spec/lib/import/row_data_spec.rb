# frozen_string_literal: true

require 'rails_helper'
require 'import/row_data'

describe Import::RowData do
  let(:row_data) { described_class.new }
  let(:attrs) { {} }
  subject { row_data.field_values(object, row, attrs) }


  describe "open_access value is sanitized, only allowing 'yes'" do
    let(:object) { :monograph }

    context "value is 'yes'" do
      let(:row) { { 'Open Access?' => 'Yes' } }

      it 'allows' do
        subject
        expect(attrs['open_access']).to eq('yes')
      end
    end

    context "value is 'Yes'" do
      let(:row) { { 'Open Access?' => 'Yes' } }

      it 'downcases' do
        subject
        expect(attrs['open_access']).to eq('yes')
      end
    end

    context "value is 'no'" do
      let(:row) { { 'Open Access?' => 'no' } }

      it 'disallows' do
        subject
        expect(attrs['open_access']).to be_nil
      end
    end

    context "value is random junk" do
      let(:row) { { 'Open Access?' => 'BlaH!' } }

      it 'disallows' do
        subject
        expect(attrs['open_access']).to be_nil
      end
    end
  end
end
