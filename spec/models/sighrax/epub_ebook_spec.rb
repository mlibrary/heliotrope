# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::EpubEbook, type: :model do
  subject { Sighrax.from_noid(epub_ebook.id) }

  let(:epub_ebook) { create(:public_file_set, content: File.open(File.join(fixture_path, 'the-whale.epub'))) }
  let(:monograph) { create(:public_monograph) }
  let(:featured_representative) { create(:featured_representative, work_id: monograph.id, file_set_id: epub_ebook.id, kind: 'epub') }

  before do
    monograph.ordered_members << epub_ebook
    monograph.save
    epub_ebook.save
    featured_representative
  end

  it 'has expected values' do
    is_expected.to be_an_instance_of described_class
    is_expected.to be_a_kind_of Sighrax::Ebook
    expect(subject.resource_type).to eq :EpubEbook
    expect(subject.parent.noid).to eq monograph.id
    expect(subject.parent.children.first.noid).to eq epub_ebook.id
    expect(subject.monograph).to be subject.parent
  end
end
