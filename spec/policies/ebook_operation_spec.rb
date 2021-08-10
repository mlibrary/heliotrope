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
      let(:institution) { create(:institution) }
      let(:product) { create(:product) }

      context "with matching affiliations" do
        before do
          license
          allow(Services).to receive(:checkpoint).and_return checkpoint
          allow(checkpoint).to receive(:licenses_for).with(actor, ebook).and_return Greensub::License.all
          create(:license_affiliation, license_id: license.id, affiliation: "member")
          create(:institution_affiliation, institution_id: institution.id, affiliation: "member")
        end

        it { is_expected.to be false }

        context 'when license entitlement' do
          before { allow_any_instance_of(Greensub::License).to receive(:allows?).with(entitlement).and_return true }

          it do
            is_expected.to be true
          end
        end
      end

      context "with mis-matched affiliations" do
        before do
          license
          allow(Services).to receive(:checkpoint).and_return checkpoint
          allow(checkpoint).to receive(:licenses_for).with(actor, ebook).and_return Greensub::License.all
          create(:license_affiliation, license_id: license.id, affiliation: "member")
          create(:institution_affiliation, institution_id: institution.id, affiliation: "walk-in")
        end

        it { is_expected.to be false }

        context 'when license entitlement' do
          before { allow_any_instance_of(Greensub::License).to receive(:allows?).with(entitlement).and_return true }

          it { is_expected.to be false }
        end
      end

      context "multiple licenses from different instituions with different affiliations" do
        let(:license2) { create(:full_license, licensee: institution2, product: product) }
        let(:institution2) { create(:institution) }

        before do
          license
          license2
          allow(Services).to receive(:checkpoint).and_return checkpoint
          allow(checkpoint).to receive(:licenses_for).with(actor, ebook).and_return Greensub::License.all
          create(:license_affiliation, license_id: license.id, affiliation: "member")
          create(:institution_affiliation, institution_id: institution.id, affiliation: "walk-in")
          create(:license_affiliation, license_id: license2.id, affiliation: "member")
          create(:institution_affiliation, institution_id: institution2.id, affiliation: "member")
        end

        it { is_expected.to be false }

        context 'when license entitlement' do
          before { allow_any_instance_of(Greensub::License).to receive(:allows?).with(entitlement).and_return true }

          # The first institution only gives the actor a "walk-in" affiliation, which isn't enough to access the resource.
          # However, the actor has a second institution that give a "member" affiliation which DOES allow access.

          it { is_expected.to be true }
        end
      end
    end

    context "individual AND institution" do
      let(:entitlement) { :entitlement }
      let(:checkpoint) { double('checkpoint') }
      let(:individual_license) { create(:full_license, licensee: individual, product: product) }
      let(:institution_license) { create(:full_license, licensee: institution, product: product) }
      let(:individual) { create(:individual) }
      let(:institution) { create(:institution) }
      let(:product) { create(:product) }

      context "individual license and an institution license with alum access" do
        before do
          individual_license
          institution_license
          allow(Services).to receive(:checkpoint).and_return checkpoint
          allow(checkpoint).to receive(:licenses_for).with(actor, ebook).and_return Greensub::License.all
          create(:license_affiliation, license_id: institution_license.id, affiliation: "member")
          create(:institution_affiliation, institution_id: institution.id, affiliation: "alum")
        end

        it { is_expected.to be false }

        context 'when license entitlement' do
          before { allow_any_instance_of(Greensub::License).to receive(:allows?).with(entitlement).and_return true }

          # The institutional license only allows "alum" access, however the individual license, which currently
          # DOES NOT support affiliations, gives the user access. The lack of individual affiliation is equivalent
          # to ALL affiliations (member, alum, walk-in). In the future maybe individuals will have affiliations, but
          # right now there's no support for it, so they just get a pass.

          it { is_expected.to be true }
        end
      end
    end
  end
end
