# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject(:e_pub_policy) { described_class.new(actor, ebook, share) }

  let(:actor) { instance_double(Anonymous, 'actor') }
  let(:ebook) { instance_double(Sighrax::Ebook, 'ebook', published?: published, tombstone?: tombstone) }
  let(:published) { false }
  let(:tombstone) { false }
  let(:share) { false }
  let(:ebook_reader_op) { instance_double(EbookReaderOperation, 'reader_op', allowed?: allowed) }
  let(:allowed) { false }

  before { allow(EbookReaderOperation).to receive(:new).with(actor, ebook).and_return ebook_reader_op }

  describe '#show?' do
    subject { e_pub_policy.show? }

    it { is_expected.to be allowed }

    context 'when share' do
      context 'when not published' do
        let(:share) { true }
        let(:allowed) { true }

        it { is_expected.to be allowed }
      end

      context 'when published' do
        let(:published) { true }
        let(:allowed) { true }

        it { is_expected.to be allowed }

        context 'when tombstone' do
          let(:tombstone) { true }
          let(:allowed) { false }

          it { is_expected.to be allowed }
        end
      end
    end
  end
end
