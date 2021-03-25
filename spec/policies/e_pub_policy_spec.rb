# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject(:e_pub_policy) { described_class.new(actor, ebook, share) }

  let(:actor) { instance_double(Anonymous, 'actor', agent_type: 'actor_type', agent_id: 'actor_id') }
  let(:ebook) { instance_double(Sighrax::Ebook, 'ebook', parent: monograph) }
  let(:monograph) { instance_double(Sighrax::Monograph, 'monograph', noid: noid, resource_type: 'monograph_type', resource_id: 'monograph_id') }
  let(:noid) { 'validnoid' }
  let(:open_access) { false }
  let(:share) { false }
  let(:is_a_user) { false }
  let(:ability_can_read) { false }
  let(:ability_can_edit) { false }
  let(:platform_admin) { false }
  let(:allow_ability_can) { true }
  let(:allow_platform_admin) { true }
  let(:sudo_actor) { false }
  let(:reader_op) { instance_double(EbookReaderOperation, 'reader_op', allowed?: allowed) }
  let(:allowed) { false }

  before do
    allow(actor).to receive(:is_a?).with(User).and_return(is_a_user)
    allow(actor).to receive(:platform_admin?).and_return(platform_admin)
    allow(Sighrax).to receive(:ability_can?).with(actor, :read, monograph).and_return(ability_can_read)
    allow(Sighrax).to receive(:ability_can?).with(actor, :edit, monograph).and_return(ability_can_edit)
    allow(Sighrax).to receive(:open_access?).with(monograph).and_return(open_access)
    allow(Sighrax).to receive(:published?).with(monograph).and_return(published)
    allow(Sighrax).to receive(:restricted?).with(monograph).and_return(restricted)
    allow(Incognito).to receive(:allow_ability_can?).with(actor).and_return(allow_ability_can)
    allow(Incognito).to receive(:allow_platform_admin?).with(actor).and_return(allow_platform_admin)
    allow(Incognito).to receive(:sudo_actor?).with(actor).and_return(sudo_actor)
    allow(EbookReaderOperation).to receive(:new).with(actor, ebook).and_return reader_op
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

        context 'ability_can_edit' do
          let(:ability_can_edit) { true }

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

      context 'allowed' do
        let(:allowed) { true }

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

        context 'ability_can_edit' do
          let(:ability_can_edit) { true }

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

      context 'allowed' do
        let(:allowed) { true }

        it { is_expected.to be true }
      end

      context 'user' do
        let(:is_a_user) { true }

        it { is_expected.to be false }

        context 'ability_can_read' do
          let(:ability_can_read) { true }

          it { is_expected.to be false }
        end

        context 'ability_can_edit' do
          let(:ability_can_edit) { true }

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
