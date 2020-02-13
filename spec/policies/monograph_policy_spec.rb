# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonographPolicy do
  subject(:monograph_policy) { described_class.new(actor, target) }

  let(:actor) { instance_double(Anonymous, 'actor') }

  describe '#epub_policy' do
    subject { monograph_policy.epub_policy }

    let(:target) { instance_double(Sighrax::Monograph, 'target', epub_featured_representative: 'epub_featured_representative') }
    let(:epub_policy) { instance_double(EPubPolicy, 'epub_policy') }

    before { allow(EPubPolicy).to receive(:new).with(actor, target.epub_featured_representative).and_return(epub_policy) }

    it { is_expected.to be epub_policy }
  end

  describe '#pdf_ebook_policy' do
    subject { monograph_policy.pdf_ebook_policy }

    let(:target) { instance_double(Sighrax::Monograph, 'target', pdf_ebook_featured_representative: 'pdf_ebook_featured_representative') }
    let(:pdf_ebook_policy) { instance_double(EPubPolicy, 'pdf_ebook_policy') }

    before { allow(EPubPolicy).to receive(:new).with(actor, target.pdf_ebook_featured_representative).and_return(pdf_ebook_policy) }

    it { is_expected.to be pdf_ebook_policy }
  end
end
