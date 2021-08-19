# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EbookOperation do
  let(:policy) { described_class.new(actor, ebook) }
  let(:actor) { Anonymous.new({}) }
  let(:ebook) { instance_double(Sighrax::Ebook, 'ebook') }

  describe '#accessible_online?' do
    subject { policy.send(:accessible_online?) }

    let(:published) { false }
    let(:tombstone) { false }

    before do
      allow(ebook).to receive(:published?).and_return published
      allow(ebook).to receive(:tombstone?).and_return tombstone
    end

    it { is_expected.to be false }

    context 'when published' do
      let(:published) { true }

      it { is_expected.to be true }

      context 'when tombstoned' do
        let(:tombstone) { true }

        it { is_expected.to be false }
      end
    end

    context 'when tombstoned' do
      let(:tombstone) { true }

      it { is_expected.to be false }

      context 'when published' do
        let(:published) { false }

        it { is_expected.to be false }
      end
    end
  end

  describe '#accessible_offline?' do
    subject { policy.send(:accessible_offline?) }

    let(:allow_download) { false }
    let(:accessible_online) { false }

    before do
      allow(ebook).to receive(:allow_download?).and_return allow_download
      allow(policy).to receive(:accessible_online?).and_return accessible_online
    end

    it { is_expected.to be false }

    context 'when allow download' do
      let(:allow_download) { true }

      it { is_expected.to be false }

      context 'when accessible online' do
        let(:accessible_online) { true }

        it { is_expected.to be true }
      end
    end

    context 'when accessible online' do
      let(:accessible_online) { true }

      it { is_expected.to be false }

      context 'when allow download' do
        let(:allow_download) { true }

        it { is_expected.to be true }
      end
    end
  end

  describe '#unrestricted?' do
    subject { policy.send(:unrestricted?) }

    let(:open_access) { false }
    let(:restricted) { false }

    before do
      allow(ebook).to receive(:open_access?).and_return open_access
      allow(ebook).to receive(:restricted?).and_return restricted
    end

    it { is_expected.to be true }

    context 'when open access' do
      let(:open_access) { true }

      it { is_expected.to be true }

      context 'when restricted' do
        let(:restricted) { true }

        it { is_expected.to be true }
      end
    end

    context 'when restricted' do
      let(:restricted) { true }

      it { is_expected.to be false }

      context 'when open access' do
        let(:open_access) { true }

        it { is_expected.to be true }
      end
    end
  end

  describe '#licensed_for?' do
    subject { policy.send(:licensed_for?, entitlement) }

    before { allow(Incognito).to receive(:developer?).with(actor).and_return true }

    context "individual" do
      let(:entitlement) { :entitlement }
      let(:checkpoint) { double('checkpoint') }
      let(:license) { create(:full_license, licensee: individual, product: product) }
      let(:individual) { create(:individual) }
      let(:product) { create(:product) }

      before do
        license
        allow(Services).to receive(:checkpoint).and_return checkpoint
        allow(checkpoint).to receive(:licenses_for).with(actor, ebook).and_return Greensub::License.all
      end

      it { is_expected.to be false }

      context 'when license entitlement' do
        before { allow_any_instance_of(Greensub::License).to receive(:allows?).with(entitlement).and_return true }

        it { is_expected.to be true }
      end
    end

    context "institution" do
      let(:entitlement) { :entitlement }
      let(:checkpoint) { double('checkpoint') }
      let(:license) { create(:full_license, licensee: institution, product: product) }
      let(:license_affiliation) { create(:license_affiliation, license: license, affiliation: 'member') }
      let(:institution) { create(:institution, identifier: institution_identifier) }
      let(:institution_identifier) { Settings.world_institution_identifier + 1 }
      let(:institution_affiliation) { create(:institution_affiliation, institution: institution, affiliation: affiliation) }
      let(:affiliation) { 'member' }
      let(:product) { create(:product) }

      before do
        license
        allow(Services).to receive(:checkpoint).and_return checkpoint
        allow(checkpoint).to receive(:licenses_for).with(actor, ebook).and_return Greensub::License.all
        allow(actor).to receive(:affiliations).with(institution).and_return([institution_affiliation])
      end

      it { is_expected.to be false }

      context 'when license entitlement' do
        before { allow_any_instance_of(Greensub::License).to receive(:allows?).with(entitlement).and_return true }

        it { is_expected.to be false }

        context 'when world institution license' do
          let(:institution_identifier) { Settings.world_institution_identifier }

          it { is_expected.to be true }
        end

        context 'when license affiliation' do
          before do
            license_affiliation
            institution_affiliation
          end

          it { is_expected.to be true }

          context 'when affiliation mismatch' do
            let(:affiliation) { 'walk-in' }

            it { is_expected.to be false }
          end
        end
      end
    end
  end
end
