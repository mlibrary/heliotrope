# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::PdfEbook, type: :model do
  subject { Sighrax.from_noid(pdf_ebook.id) }

  let(:pdf_ebook) { create(:public_file_set, content: File.open(File.join(fixture_path, 'hello.pdf'))) }
  let(:monograph) { create(:public_monograph) }
  let(:featured_representative) { create(:featured_representative, work_id: monograph.id, file_set_id: pdf_ebook.id, kind: 'pdf_ebook') }

  before do
    monograph.ordered_members << pdf_ebook
    monograph.save
    pdf_ebook.save
    featured_representative
  end

  it 'has expected values' do
    is_expected.to be_an_instance_of described_class
    is_expected.to be_a_kind_of Sighrax::Ebook
    expect(subject.resource_type).not_to eq :PDFEbook
    expect(subject.parent.noid).to eq monograph.id
    expect(subject.parent.children.first.noid).to eq pdf_ebook.id
    expect(subject.monograph).to be subject.parent
    expect(subject.watermarkable?).to be true
  end
end
