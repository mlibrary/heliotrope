# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntityPolicy do
  subject(:entity_policy) { described_class.new(actor, target) }

  let(:actor) { instance_double(Anonymous, 'actor') }
  let(:target) { instance_double(Sighrax::Resource, 'target', parent: parent) }
  let(:parent) { instance_double(Sighrax::Work, 'parent') }

  describe '#download?' do
    subject { entity_policy.download? }

    let(:downloadable) { false }
    let(:allow_ability_can) { true }
    let(:allow_platform_admin) { true }
    let(:developer) { false }

    before do
      allow(Incognito).to receive(:allow_platform_admin?).with(actor).and_return(allow_platform_admin)
      allow(Incognito).to receive(:allow_ability_can?).with(actor).and_return(allow_ability_can)
      allow(Incognito).to receive(:developer?).with(actor).and_return(developer)
      allow(Sighrax).to receive(:downloadable?).with(target).and_return(downloadable)
    end

    it { is_expected.to be false }

    context 'downloadable' do
      let(:downloadable) { true }

      context 'platform_admin' do
        let(:platform_admin) { true }

        before { allow(Sighrax).to receive(:platform_admin?).with(actor).and_return(platform_admin) }

        it { is_expected.to be true }

        context 'ability_can_edit' do
          let(:platform_admin) { false }
          let(:ability_can_edit) { true }

          before { allow(Sighrax).to receive(:ability_can?).with(actor, :edit, target).and_return(ability_can_edit) }

          it { is_expected.to be true }

          context 'tombstone' do
            let(:ability_can_edit) { false }
            let(:tombstone) { true }

            before { allow(Sighrax).to receive(:tombstone?).with(target).and_return(tombstone) }

            it { is_expected.to be false }

            context 'Incognito' do
              context 'platform admin' do
                let(:platform_admin) { true }

                it { is_expected.to be true }

                context 'disallow platform admin' do
                  let(:allow_platform_admin) { false }

                  it { is_expected.to be false }
                end
              end

              context 'ability can' do
                let(:ability_can_edit) { true }

                it { is_expected.to be true }

                context 'disallow ability can' do
                  let(:allow_ability_can) { false }

                  it { is_expected.to be false }
                end
              end
            end

            context 'deny download' do
              let(:tombstone) { false }
              let(:allow_download) { false }

              before { allow(Sighrax).to receive(:allow_download?).with(target).and_return(allow_download) }

              it { is_expected.to be false }

              context 'unpublished' do
                let(:allow_download) { true }
                let(:published) { false }

                before { allow(Sighrax).to receive(:published?).with(target).and_return(published) }

                it { is_expected.to be false }

                context 'instance of asset' do
                  let(:published) { true }
                  let(:instance_of_asset) { true }

                  before { allow(target).to receive(:instance_of?).with(Sighrax::Asset).and_return(instance_of_asset) }

                  it { is_expected.to be true }

                  context 'open access' do
                    let(:instance_of_asset) { false }
                    let(:open_access) { true }

                    before { allow(Sighrax).to receive(:open_access?).with(parent).and_return(open_access) }

                    it { is_expected.to be true }

                    context 'unrestricted' do
                      let(:open_access) { false }
                      let(:restricted) { false }

                      before { allow(Sighrax).to receive(:restricted?).with(parent).and_return(restricted) }

                      it { is_expected.to be true }

                      context 'restricted' do
                        let(:restricted) { true }
                        let(:access) { false }

                        before { allow(Sighrax).to receive(:access?).with(actor, parent).and_return(access) }

                        it { is_expected.to be false }

                        context 'access' do
                          let(:access) { true }

                          it { is_expected.to be true }
                        end

                        context 'developer' do
                          let(:developer) { true }
                          let(:download_op) { instance_double(EbookDownloadOperation, 'download_op', allowed?: allowed) }
                          let(:allowed)  { false }

                          before do
                            allow(Sighrax).to receive(:access?).with(actor, parent)
                            allow(EbookDownloadOperation).to receive(:new).with(actor, target).and_return download_op
                          end

                          it { is_expected.to be false }
                          it { expect(Sighrax).not_to have_received(:access?).with(actor, parent) }

                          context 'allowed' do
                            let(:allowed) { true }

                            it { is_expected.to be true }
                            it { expect(Sighrax).not_to have_received(:access?).with(actor, parent) }
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
