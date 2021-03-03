# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::MobiEbook, type: :model do
  subject { Sighrax.from_noid(mobi_ebook.id) }

  let(:mobi_ebook) { create(:public_file_set, content: File.open(File.join(fixture_path, 'present.txt'))) }
  let(:monograph) { create(:public_monograph) }
  let(:featured_representative) { create(:featured_representative, work_id: monograph.id, file_set_id: mobi_ebook.id, kind: 'mobi') }

  before do
    monograph.ordered_members << mobi_ebook
    monograph.save
    mobi_ebook.save
    featured_representative
  end

  it 'has expected values' do
    is_expected.not_to be_an_instance_of described_class
    is_expected.to be_an_instance_of Sighrax::Mobipocket # Deprecated
    is_expected.to be_a_kind_of Sighrax::Ebook
    is_expected.to be_a_kind_of Sighrax::ElectronicBook # Deprecated
    expect(subject.resource_type).not_to eq :MobiEbook
    expect(subject.resource_type).to eq :Mobipocket # Deprecated
    expect(subject.parent.noid).to eq monograph.id
    expect(subject.parent.children.first.noid).to eq mobi_ebook.id
    expect(subject.monograph).to be subject.parent
  end
end
