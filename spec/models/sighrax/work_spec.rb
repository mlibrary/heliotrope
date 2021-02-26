# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Work, type: :model do
  context 'instance' do
    subject { described_class.send(:new, noid, data) }

    let(:noid) { 'validnoid' }
    let(:data) { {} }

    it 'has expected values' do
      is_expected.to be_an_instance_of described_class
      is_expected.to be_a_kind_of Sighrax::Model
      expect(subject.resource_type).to eq :Work
      expect(subject.parent).to be_an_instance_of Sighrax::NullEntity
      expect(subject.children).to be_empty
    end
  end

  context 'monograph without children' do
    subject { Sighrax.from_noid(monograph.id) }

    let(:monograph) { create(:public_monograph) }

    it 'has no parent and no children' do
      expect(subject.parent).to be_an_instance_of(Sighrax::NullEntity)
      expect(subject.children).to be_empty
    end
  end

  context 'monograph with children' do
    subject { Sighrax.from_noid(monograph.id) }

    let(:monograph) { create(:public_monograph) }
    let(:cover) { create(:public_file_set) }
    let(:epub) { create(:public_file_set) }
    let(:pdf_ebook) { create(:public_file_set) }
    let(:asset) { create(:public_file_set) }
    let(:epub_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:pdf_ebook_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: pdf_ebook.id, kind: 'pdf_ebook') }

    before do
      monograph.ordered_members = [cover, epub, pdf_ebook, asset]
      monograph.save!
      cover.save!
      epub.save!
      pdf_ebook.save!
      asset.save!
      epub_fr
      pdf_ebook_fr
    end

    it 'has children but no parent' do
      expect(subject.parent).to be_an_instance_of(Sighrax::NullEntity)
      expect(subject.children).to contain_exactly(Sighrax.from_noid(cover.id),
                                                  Sighrax.from_noid(epub.id),
                                                  Sighrax.from_noid(pdf_ebook.id),
                                                  Sighrax.from_noid(asset.id))
      subject.children.each do |child|
        expect(child.parent).to eq subject
      end
    end
  end
end
