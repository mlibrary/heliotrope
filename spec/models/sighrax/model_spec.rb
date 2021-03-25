# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Model, type: :model do
  context 'instance' do
    subject { described_class.send(:new, noid, data) }

    let(:noid) { 'validnoid' }
    let(:data) { {} }

    it 'has expected values' do
      is_expected.to be_an_instance_of described_class
      is_expected.to be_a_kind_of Sighrax::Entity
      expect(subject.resource_type).to eq :Model
      expect(subject.children).to be_empty
      expect(subject.deposited?).to be true
      expect(subject.modified).to be nil
      expect(subject.parent).to be_an_instance_of Sighrax::NullEntity
      expect(subject.published?).to be false
      expect(subject.publisher).to be_an_instance_of(Sighrax::NullPublisher)
      expect(subject.timestamp).to be nil
      expect(subject.title).to eq noid
      expect(subject.tombstone?).to be false
    end
  end

  describe '#deposited?' do
    subject { described_class.send(:new, noid, data).deposited? }

    let(:noid) { 'validnoid' }
    let(:data) { {} }

    # Sipity workflow state is NOT stored on the
    # Fedora object hence this test assumes the
    # solr document key is "suppressed_bsi".

    it { is_expected.to be true }

    context 'when suppressed blank?' do
      let(:data) { { 'suppressed_bsi' => '' } }

      it { is_expected.to be true }
    end

    context 'when suppressed present?' do
      let(:data) { { 'suppressed_bsi' => 'anything' } }

      it { is_expected.to be false }
    end

    context 'when suppressed false' do
      let(:data) { { 'suppressed_bsi' => false } }

      it { is_expected.to be true }
    end

    context 'when suppressed true' do
      let(:data) { { 'suppressed_bsi' => true } }

      it { is_expected.to be false }
    end
  end

  context 'file set' do
    subject { Sighrax.from_noid(file_set.id) }

    let(:file_set) { create(:public_file_set) }

    it 'is a file set model' do
      is_expected.to be_an_instance_of(Sighrax::Resource)
      is_expected.to be_a_kind_of(Sighrax::Model)
      expect(subject.resource_type).to eq :Resource
      expect(subject.send(:model_type)).to eq 'FileSet'
    end

    it { expect(subject.children).to be_empty }

    describe '#modified' do
      it { expect(subject.modified).to eq Sighrax::Entity.null_entity.modified }

      context 'date modified' do
        let(:date_modified) { Time.parse(Time.now.iso8601).utc } # Strip fractions of a second

        before do
          file_set.date_modified = date_modified
          file_set.save
        end

        it do
          expect(subject.modified).to eq date_modified
        end
      end
    end

    it { expect(subject.parent).to eq Sighrax::Entity.null_entity }

    describe '#published?' do
      it { expect(subject.published?).to be true }

      context 'published' do
        before do
          file_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          file_set.save
        end

        it { expect(subject.published?).to be false }
      end
    end

    describe '#timestamp' do
      let(:solr_document) { subject.send(:data) }
      let(:timestamp) { Time.parse(Array(solr_document['timestamp']).first).utc }

      it { expect(subject.timestamp).to eq timestamp }
    end

    it { expect(subject.title).to eq file_set.title.first }

    describe '#tombstone?' do
      it { expect(subject.tombstone?).to be false }

      context 'tombstone' do
        before do
          file_set.permissions_expiration_date = "1999-01-01"
          file_set.save
        end

        it { expect(subject.tombstone?).to be true }
      end
    end
  end

  context 'monograph' do
    subject { Sighrax.from_noid(monograph.id) }

    let(:monograph) { create(:public_monograph) }

    it 'is a monograph model' do
      is_expected.to be_an_instance_of(Sighrax::Monograph)
      is_expected.to be_a_kind_of(Sighrax::Model)
      expect(subject.resource_type).to eq :Monograph
      expect(subject.send(:model_type)).to eq 'Monograph'
    end

    it { expect(subject.children).to be_empty }

    describe '#modified' do
      it { expect(subject.modified).to eq Sighrax::Entity.null_entity.modified }

      context 'date modified' do
        let(:date_modified) { Time.parse(Time.now.iso8601).utc } # Strip fractions of a second

        before do
          monograph.date_modified = date_modified
          monograph.save
        end

        it { expect(subject.modified).to eq date_modified }
      end
    end

    it { expect(subject.parent).to eq Sighrax::Entity.null_entity }

    describe '#published?' do
      it { expect(subject.published?).to be true }

      context 'published' do
        before do
          monograph.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          monograph.save
        end

        it { expect(subject.published?).to be false }
      end
    end

    describe '#timestamp' do
      let(:solr_document) { subject.send(:data) }
      let(:timestamp) { Time.parse(Array(solr_document['timestamp']).first).utc }

      it { expect(subject.timestamp).to eq timestamp }
    end

    it { expect(subject.title).to eq monograph.title.first }

    describe '#tombstone?' do
      it { expect(subject.tombstone?).to be false }

      # TODO: Currently Monographs don't have permission expiration dates
      xcontext 'tombstone' do
        before do
          monograph.permissions_expiration_date = "1999-01-01"
          monograph.save
        end

        it { expect(subject.tombstone?).to be true }
      end
    end
  end
end
