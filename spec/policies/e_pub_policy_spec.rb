# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject(:e_pub_policy) { described_class.new(actor, target, share) }

  let(:actor) { double('actor', agent_type: 'actor_type', agent_id: 'actor_id', individual: nil, institutions: [institution]) }
  let(:institution) { double('institution', products: [product]) }
  let(:product) { double('product', identifier: 'product') }
  let(:target) { double('target', parent: parent) }
  let(:parent) { double('parent', noid: noid, resource_type: 'parent_type', resource_id: 'parent_id') }
  let(:noid) { 'validnoid' }
  let(:component) { double('component', products: products) }
  let(:products) { [] }

  let(:open_access) { false }
  let(:share) { false }
  let(:is_a_user) { false }
  let(:ability_can_read) { false }
  let(:ability_can_manage) { false }
  let(:platform_admin) { false }
  let(:allow_ability_can) { true }
  let(:allow_platform_admin) { true }
  let(:sudo_actor) { false }

  before do
    allow(actor).to receive(:is_a?).with(User).and_return(is_a_user)
    allow(actor).to receive(:platform_admin?).and_return(platform_admin)
    allow(Sighrax).to receive(:ability_can?).with(actor, :read, parent).and_return(ability_can_read)
    allow(Sighrax).to receive(:ability_can?).with(actor, :manage, parent).and_return(ability_can_manage)
    allow(Sighrax).to receive(:open_access?).with(parent).and_return(open_access)
    allow(Sighrax).to receive(:published?).with(parent).and_return(published)
    allow(Sighrax).to receive(:restricted?).with(parent).and_return(restricted)
    allow(Greensub::Component).to receive(:find_by).with(noid: noid).and_return(component)
    allow(Incognito).to receive(:allow_ability_can?).with(actor).and_return(allow_ability_can)
    allow(Incognito).to receive(:allow_platform_admin?).with(actor).and_return(allow_platform_admin)
    allow(Incognito).to receive(:sudo_actor?).with(actor).and_return(sudo_actor)
  end

  describe '#show?' do
    subject { e_pub_policy.show? }

    context 'unrestricted unpublished' do
      let(:restricted) { false }
      let(:published) { false }

      it { is_expected.to be false }

      context 'user' do
        let(:is_a_user) { true }

        it { is_expected.to be false }

        context 'ability_can_read' do
          let(:ability_can_read) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_ability_can) { false }

            it { is_expected.to be false }
          end
        end

        context 'ability_can_manage' do
          let(:ability_can_manage) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_ability_can) { false }

            it { is_expected.to be false }
          end
        end

        context 'platform_admin' do
          let(:platform_admin) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_platform_admin) { false }

            it { is_expected.to be false }
          end
        end
      end
    end

    context 'unrestricted published' do
      let(:restricted) { false }
      let(:published) { true }

      it { is_expected.to be true }
    end

    context 'restricted unpublished' do
      let(:restricted) { true }
      let(:published) { false }

      it { is_expected.to be false }

      context 'open access' do
        let(:open_access) { true }

        it { is_expected.to be false }
      end

      context 'share' do
        let(:share) { true }

        it { is_expected.to be false }
      end

      context 'subscriber' do
        let(:products) { [product] }

        it { is_expected.to be false }
      end

      context 'user' do
        let(:is_a_user) { true }

        it { is_expected.to be false }

        context 'ability_can_read' do
          let(:ability_can_read) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_ability_can) { false }

            it { is_expected.to be false }
          end
        end

        context 'ability_can_manage' do
          let(:ability_can_manage) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_ability_can) { false }

            it { is_expected.to be false }
          end
        end

        context 'platform_admin' do
          let(:platform_admin) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_platform_admin) { false }

            it { is_expected.to be false }
          end
        end
      end
    end

    context 'restricted published' do
      let(:restricted) { true }
      let(:published) { true }

      it { is_expected.to be false }

      context 'open access' do
        let(:open_access) { true }

        it { is_expected.to be true }
      end

      context 'share' do
        let(:share) { true }

        it { is_expected.to be true }
      end

      context 'allow read product' do
        let(:products) { [read_product] }
        let(:read_product) { instance_double(Greensub::Product, 'read_product', identifier: 'read_product_identifier') }

        before do
          Settings.allow_read_products = [read_product.identifier]
          allow(Greensub::Product).to receive(:where).with(identifier: Settings.allow_read_products).and_return([read_product])
        end

        after { Settings.allow_read_products = nil }

        it { is_expected.to be true }
      end

      context 'subscriber' do
        let(:products) { [product] }

        it { is_expected.to be true }

        context 'Incognito' do
          let(:sudo_actor) { true }

          it { is_expected.to be false }
        end
      end

      context 'user' do
        let(:is_a_user) { true }

        it { is_expected.to be false }

        context 'ability_can_read' do
          let(:ability_can_read) { true }

          it { is_expected.to be false }
        end

        context 'ability_can_manage' do
          let(:ability_can_manage) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_ability_can) { false }

            it { is_expected.to be false }
          end
        end

        context 'platform_admin' do
          let(:platform_admin) { true }

          it { is_expected.to be true }

          context 'Incognito' do
            let(:allow_platform_admin) { false }

            it { is_expected.to be false }
          end
        end
      end
    end
  end
end
