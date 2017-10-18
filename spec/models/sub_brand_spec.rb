# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubBrand, type: :model do
  let(:umich) { build :press, subdomain: 'umich' }
  let(:sub_brand) { build(:sub_brand, press: umich) }

  context 'validation' do
    let(:sub_brand) { described_class.new }

    it 'must belong to a press' do
      expect(sub_brand.valid?).to eq false
      expect(sub_brand.errors.messages[:press]).to eq ["must exist", "can't be blank"]
    end

    it 'must have a title' do
      expect(sub_brand.valid?).to eq false
      expect(sub_brand.errors.messages[:title]).to eq ["can't be blank"]
    end
  end

  context 'Membership:' do
    let(:series) { build :sub_brand, title: 'The Complete Works of William Shakespeare', press: umich }
    let(:imprint) { build :sub_brand, title: 'Imprint for my Press', press: umich }

    it 'A sub-brand can contain other sub-brands' do
      sub_brand.sub_brands += [series, imprint]
      sub_brand.save!

      expect(sub_brand.sub_brands).to contain_exactly(series, imprint)
      expect(series.parent).to eq sub_brand
      expect(imprint.parent).to eq sub_brand

      expect(sub_brand.valid?).to eq true
      expect(series.valid?).to eq true
      expect(imprint.valid?).to eq true
    end

    it 'A sub-brand cannot contain itself' do
      sub_brand.sub_brands << sub_brand
      expect(sub_brand.sub_brands).to eq [sub_brand]
      expect(sub_brand.valid?).to eq false
      expect(sub_brand.errors.messages[:sub_brands]).to include "can't contain itself"
    end

    it 'A sub-brand cannot contain its parent (no loops)' do
      imprint.sub_brands << sub_brand
      imprint.save!

      sub_brand.sub_brands << imprint
      expect(sub_brand.valid?).to eq false
      expect(sub_brand.errors.messages[:sub_brands]).to include "can't contain its parent"
    end
  end
end
