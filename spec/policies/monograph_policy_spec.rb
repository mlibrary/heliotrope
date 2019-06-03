# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonographPolicy do
  subject(:monograph_policy) { described_class.new(actor, target) }

  let(:actor) { instance_double(Anonymous, 'actor') }
  let(:target) { instance_double(Sighrax::Monograph, 'target', epub_featured_representative: 'epub_featured_representative') }

  describe '#epub_policy' do
    subject { monograph_policy.epub_policy }

    let(:epub_policy) { instance_double(EPubPolicy, 'epub_policy') }

    before { allow(EPubPolicy).to receive(:new).with(actor, target.epub_featured_representative).and_return(epub_policy) }

    it { is_expected.to be epub_policy }
  end
end
