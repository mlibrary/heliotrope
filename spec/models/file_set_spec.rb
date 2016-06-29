require 'rails_helper'

describe FileSet do
  let(:file_set) { described_class.new }
  let(:sort_date) { '2014-01-03' }
  let(:bad_sort_date) { 'NOT-A-DATE' }

  before do
    described_class.destroy_all
  end

  it 'has a valid sort_date' do
    file_set.sort_date = sort_date
    file_set.apply_depositor_metadata('admin@example.com')
    expect(file_set.save!).to be true
    expect(file_set.reload.sort_date).to eq sort_date
  end

  it 'does not have an invalid sort date' do
    file_set.sort_date = bad_sort_date
    file_set.apply_depositor_metadata('admin@example.com')
    expect { file_set.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end
end
