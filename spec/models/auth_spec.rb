# frozen_string_literal: true

require 'rails_helper'

# NOTE: Private method subscribing_institutions is not tested.
# You just got to have faith.

RSpec.describe Auth, type: :model do
  subject { auth }

  let(:auth) { described_class.new(actor, entity) }
  let(:actor) { Anonymous.new({}) }
  let(:entity) { Sighrax::Entity.null_entity }

  it { is_expected.to be_an_instance_of(described_class) }

  describe '#return_location' do
    subject { auth.return_location }

    it { is_expected.to be nil }

    context 'Publisher' do
      let(:press) { create(:press) }
      let(:entity) { Sighrax::Publisher.from_press(press) }

      it { is_expected.to eq Rails.application.routes.url_helpers.press_catalog_path(press) }
    end

    context 'Monograph' do
      let(:monograph) { create(:monograph) }
      let(:entity) { Sighrax.from_noid(monograph.id) }

      it { is_expected.to eq Rails.application.routes.url_helpers.monograph_catalog_path(monograph) }
    end

    context 'Resource' do
      let(:resource) { create(:file_set) }
      let(:entity) { Sighrax.from_noid(resource.id) }

      it { is_expected.to eq Rails.application.routes.url_helpers.hyrax_file_set_path(resource) }
    end
  end

  describe '#actor_authorized? and #actor_unauthorized?' do
    it do
      expect(auth.actor_authorized?).to be false
      expect(auth.actor_unauthorized?).to be true
    end

    context 'monograph' do
      let(:monograph) { create(:monograph) }
      let(:entity) { Sighrax.from_noid(monograph.id) }
      let(:restricted) { false }
      let(:open_access) { false }
      let(:ebook) { instance_double(Sighrax::Ebook) }
      let(:policy) { instance_double(EPubPolicy, 'policy', show?: show) }
      let(:show) { false }

      before do
        allow(entity).to receive(:restricted?).and_return(restricted)
        allow(entity).to receive(:open_access?).and_return(open_access)
        allow(entity).to receive(:ebook).and_return(ebook)
        allow(EPubPolicy).to receive(:new).with(actor, ebook, false).and_return(policy)
      end

      it do
        expect(auth.actor_authorized?).to be true
        expect(auth.actor_unauthorized?).to be false
      end

      context 'restricted' do
        let(:restricted) { true }

        it do
          expect(auth.actor_authorized?).to be false
          expect(auth.actor_unauthorized?).to be true
        end

        context 'open_access' do
          let(:open_access) { true }

          it do
            expect(auth.actor_authorized?).to be true
            expect(auth.actor_unauthorized?).to be false
          end
        end

        context 'show' do
          let(:show) { true }

          it do
            expect(auth.actor_authorized?).to be true
            expect(auth.actor_unauthorized?).to be false
          end
        end
      end
    end
  end

  describe '#actor_authenticated?' do
    subject { auth.actor_authenticated? }

    it { is_expected.to be false }

    context 'institutions' do
      let(:institution) { 'institution' }
      before { allow(actor).to receive(:institutions).and_return([institution]) }

      it { is_expected.to be true }
    end
  end

  describe '#actor_single_sign_on_authenticated?' do
    subject { auth.actor_single_sign_on_authenticated? }

    it { is_expected.to be false }

    context 'identity provider' do
      let(:request_attributes) { { identity_provider: 'entity_id' } }

      before { allow(actor).to receive(:request_attributes).and_return(request_attributes) }

      it { is_expected.to be true }
    end

    context 'incognito developer' do
      before { allow(Incognito).to receive(:developer?).with(actor).and_return(true) }

      it { is_expected.to be true }
    end
  end

  describe '#actor_subscribing_institutions' do
    subject { auth.actor_subscribing_institutions }

    let(:institutions) { ['institution'] }
    let(:monograph_subscribing_institutions) { ['monograph_institution_1', 'monograph_institution_2'] }
    let(:publisher_subscribing_institutions) { monograph_subscribing_institutions + ['non_monograph_institution_3', 'non_monograph_institution_4'] }

    before do
      allow(actor).to receive(:institutions).and_return(institutions)
      allow_any_instance_of(Auth).to receive(:monograph_subscribing_institutions).and_return(monograph_subscribing_institutions)
      allow_any_instance_of(Auth).to receive(:publisher_subscribing_institutions).and_return(publisher_subscribing_institutions)
    end

    it { is_expected.to be_empty }

    context 'one subscription to monograph' do
      let(:institutions) { ['monograph_institution_1'] }

      it { is_expected.to contain_exactly('monograph_institution_1') }
    end

    context 'two subscriptions to monograph' do
      let(:institutions) { ['monograph_institution_1', 'monograph_institution_2'] }

      it { is_expected.to contain_exactly('monograph_institution_1', 'monograph_institution_2') }
    end

    context 'one non subscription to monograph' do
      let(:institutions) { ['non_monograph_institution_3'] }

      it { is_expected.to contain_exactly('non_monograph_institution_3') }
    end

    context 'two non subscription to monograph' do
      let(:institutions) { ['non_monograph_institution_3', 'non_monograph_institution_4'] }

      it { is_expected.to contain_exactly('non_monograph_institution_3', 'non_monograph_institution_4') }
    end

    context 'one subscription to monograph and one non subscription to monograph' do
      let(:institutions) { ['monograph_institution_2', 'non_monograph_institution_4'] }

      it { is_expected.to contain_exactly('monograph_institution_2') }
    end
  end

  describe '#publisher?, #publisher_subdomain, #publisher_name, #publisher_restricted_content? and #publisher_individual_subscribers?' do
    it do
      expect(auth.publisher?).to be false
      expect(auth.publisher_subdomain).to eq 'null_subdomain'
      expect(auth.publisher_name).to be 'Null Publisher Name'
      expect(auth.publisher_restricted_content?).to be false
      expect(auth.publisher_individual_subscribers?).to be false
    end

    context 'Publisher' do
      let(:press) { create(:press) }
      let(:entity) { Sighrax::Publisher.from_press(press) }

      it do
        expect(auth.publisher?).to be true
        expect(auth.publisher_subdomain).to eq entity.subdomain
        expect(auth.publisher_name).to eq entity.name
        expect(auth.publisher_restricted_content?).to be false
        expect(auth.publisher_individual_subscribers?).to be false
      end

      context 'heb' do
        let(:press) { create(:press, subdomain: 'heb') }

        it do
          expect(auth.publisher_subdomain).to eq 'heb'
          expect(auth.publisher_restricted_content?).to be false
          expect(auth.publisher_individual_subscribers?).to be true
        end
      end

      context 'heliotrope' do
        let(:press) { create(:press, subdomain: 'heliotrope') }

        it do
          expect(auth.publisher_subdomain).to eq 'heliotrope'
          expect(auth.publisher_restricted_content?).to be false
          expect(auth.publisher_individual_subscribers?).to be false
        end

        context 'incognito developer' do
          before { allow(Incognito).to receive(:developer?).with(actor).and_return(true) }

          it { expect(auth.publisher_individual_subscribers?).to be true }
        end
      end
    end

    context 'Monograph' do
      let(:monograph) { create(:monograph) }
      let(:entity) { Sighrax.from_noid(monograph.id) }

      it do
        expect(auth.publisher_subdomain).to eq entity.publisher.subdomain
        expect(auth.publisher_restricted_content?).to be false
        expect(auth.publisher_individual_subscribers?).to be false
      end

      context 'component' do
        before { Greensub::Component.create!(identifier: entity.resource_token, name: entity.title, noid: entity.noid) }

        it { expect(auth.publisher_restricted_content?).to be true }
      end
    end

    context 'Resource' do
      let(:monograph) do
        m = create(:monograph)
        m.ordered_members << resource
        m.save!
        resource.save!
        m
      end
      let(:resource) { create(:file_set) }
      let(:entity) { Sighrax.from_noid(resource.id) }

      before { monograph }

      it do
        expect(auth.publisher_subdomain).to eq entity.parent.publisher.subdomain
        expect(auth.publisher_restricted_content?).to be false
        expect(auth.publisher_individual_subscribers?).to be false
      end
    end
  end

  describe '#publisher_subscribing_institutions' do
    subject { auth.publisher_subscribing_institutions }

    it { is_expected.to be_empty }

    context 'subscribing institutions' do
      let(:press) { create(:press) }
      let(:publisher) { Sighrax::Publisher.from_press(press) }
      let(:noids) { ['validnoid'] }
      let(:institutions) { ['institution'] }

      before do
        allow(publisher).to receive(:work_noids).with(true).and_return(noids)
        allow_any_instance_of(Auth).to receive(:subscribing_institutions).and_return([])
        allow_any_instance_of(Auth).to receive(:subscribing_institutions).with(noids).and_return(institutions)
      end

      it { is_expected.to be_empty }

      context 'Publisher' do
        let(:entity) { publisher }

        it { is_expected.to be institutions }
      end
    end
  end

  describe '#monograph?, #monograph_id, #monograph_buy_url?, #monograph_buy_url, #monograph_worldcat_url? and #monograph_worldcat_url' do
    it do
      expect(auth.monograph?).to be false
      expect(auth.monograph_id).to eq 'null_noid'
      expect(auth.monograph_buy_url?).to be false
      expect(auth.monograph_buy_url).to be ''
      expect(auth.monograph_worldcat_url?).to be false
      expect(auth.monograph_worldcat_url).to be ''
    end

    context 'Monograph' do
      let(:monograph) { create(:monograph) }
      let(:entity) { Sighrax.from_noid(monograph.id) }

      it do
        expect(auth.monograph?).to be true
        expect(auth.monograph_id).to eq monograph.id
      end

      context 'delegate' do
        before do
          allow(entity).to receive(:buy_url).and_return('buy_url')
          allow(entity).to receive(:worldcat_url).and_return('worldcat_url')
        end

        it do
          expect(auth.monograph_buy_url?).to be true
          expect(auth.monograph_buy_url).to eq 'buy_url'
          expect(auth.monograph_worldcat_url?).to be true
          expect(auth.monograph_worldcat_url).to eq 'worldcat_url'
        end
      end
    end

    context 'Resource' do
      let(:monograph) do
        m = create(:monograph)
        m.ordered_members << resource
        m.save!
        resource.save!
        m
      end
      let(:resource) { create(:file_set) }
      let(:entity) { Sighrax.from_noid(resource.id) }

      before { monograph }

      it do
        expect(auth.monograph?).to be true
        expect(auth.monograph_id).to eq monograph.id
      end
    end
  end

  describe '#monograph_subscribing_institutions' do
    subject { auth.monograph_subscribing_institutions }

    it { is_expected.to be_empty }

    context 'subscribing institutions' do
      let(:mono) { create(:monograph) }
      let(:monograph) { Sighrax.from_noid(mono.id) }
      let(:institutions) { ['institution'] }

      before do
        allow_any_instance_of(Auth).to receive(:subscribing_institutions).and_return([])
        allow_any_instance_of(Auth).to receive(:subscribing_institutions).with(monograph.noid).and_return(institutions)
      end

      it { is_expected.to be_empty }

      context 'Monograph' do
        let(:entity) { monograph }

        it { is_expected.to be institutions }
      end
    end
  end

  describe '#resource? and #resource_id' do
    it do
      expect(auth.resource?).to eq false
      expect(auth.resource_id).to eq 'null_noid'
    end

    context 'Resource' do
      let(:resource) { create(:file_set) }
      let(:entity) { Sighrax.from_noid(resource.id) }

      it do
        expect(auth.resource?).to eq true
        expect(auth.resource_id).to eq resource.id
      end
    end
  end

  describe '#institution? and #institution' do
    it do
      expect(auth.institution?).to be false
      expect(auth.institution).to be nil
    end

    context 'actor institutions' do
      before { allow(actor).to receive(:institutions).and_return(['institution_1', 'institution_2']) }

      it do
        expect(auth.institution?).to be true
        expect(auth.institution).to eq 'institution_1'
      end

      context 'actor subscribing institutions' do
        before { allow(auth).to receive(:actor_subscribing_institutions).and_return(['institution_3', 'instiution_4']) }

        it do
          expect(auth.institution?).to be true
          expect(auth.institution).to eq 'institution_3'
        end
      end
    end
  end
end
