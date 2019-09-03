# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntityPolicy do
  subject(:entity_policy) { described_class.new(actor, target) }

  let(:actor) { double('actor') }
  let(:target) { double('target', parent: parent) }
  let(:parent) { double('parent') }

  describe '#download?' do
    subject { entity_policy.download? }

    let(:downloadable) { false }

    before { allow(Sighrax).to receive(:downloadable?).with(target).and_return(downloadable) }

    it { is_expected.to be false }

    context 'downloadable' do
      let(:downloadable) { true }

      context 'platform_admin' do
        let(:platform_admin) { true }

        before { allow(Sighrax).to receive(:platform_admin?).with(actor).and_return(platform_admin) }

        it { is_expected.to be true }

        context 'hyrax_can_edit' do
          let(:platform_admin) { false }
          let(:hyrax_can_edit) { true }

          before { allow(Sighrax).to receive(:hyrax_can?).with(actor, :edit, target).and_return(hyrax_can_edit) }

          it { is_expected.to be true }

          context 'tombstone' do
            let(:hyrax_can_edit) { false }
            let(:tombstone) { true }

            before { allow(Sighrax).to receive(:tombstone?).with(target).and_return(tombstone) }

            it { is_expected.to be false }

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
