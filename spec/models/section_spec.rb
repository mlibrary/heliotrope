require 'rails_helper'

describe Section do
  let(:instance) { described_class.new }
  let(:date) { DateTime.now }
  let(:monograph_id) { '123' }

  it "has date_published" do
    instance.date_published = [date]
    expect(instance.date_published).to eq [date]
  end

  it "has a monograph_id" do
    instance.monograph_id = monograph_id
    expect(instance.monograph_id).to eq monograph_id
  end

  it "indexes the monograph_id" do
    instance.monograph_id = monograph_id
    indexed = instance.to_solr
    expect(indexed['monograph_id_ssim']).to eq [monograph_id]
  end
end
