# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Ebook, type: :model do
  subject { described_class.send(:new, noid, data) }

  let(:noid) { 'validnoid' }
  let(:data) { {} }

  it 'has expected values' do
    is_expected.to be_an_instance_of described_class
    is_expected.to be_a_kind_of Sighrax::Resource
    is_expected.to be_a_kind_of Sighrax::Asset # Deprecated
    expect(subject.resource_type).to eq :Ebook
  end

  context 'delegates to parent monograph' do
    let(:data) { { 'monograph_id_ssim' => 'monograph_id' } }

    let(:monograph) { instance_double(
      Sighrax::Monograph,
      'parent',
      open_access?: open_access,
      products: products,
      restricted?: restricted,
      tombstone?: tombstone
    ) }
    let(:open_access) { double('open_access') }
    let(:products) { double('products') }
    let(:tombstone) { double('tombstone') }
    let(:restricted) { double('restricted') }

    before { allow(Sighrax).to receive(:from_noid).with('monograph_id').and_return(monograph) }

    it 'delegates to parent monograph' do
      expect(subject.parent).to be monograph
      expect(subject.monograph).to be monograph
      expect(subject.open_access?).to be open_access
      expect(subject.products).to be products
      expect(subject.restricted?).to be restricted
      expect(subject.tombstone?).to be tombstone
    end
  end
end
