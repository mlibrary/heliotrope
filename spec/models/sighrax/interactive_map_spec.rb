# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::InteractiveMap, type: :model do
  subject { Sighrax.from_noid(imap.id) }

  let(:imap) { create(:public_file_set, content: File.open(File.join(fixture_path, 'empty.txt'))) }
  let(:monograph) { create(:public_monograph) }

  before do
    monograph.ordered_members << imap
    monograph.save
    imap.resource_type = ['interactive map']
    imap.save
  end

  it 'has expected values' do
    is_expected.to be_an_instance_of described_class
    is_expected.to be_a_kind_of Sighrax::Resource
    is_expected.to be_a_kind_of Sighrax::Asset # Deprecated
    expect(subject.resource_type).to eq :InteractiveMap
    expect(subject.parent.noid).to eq monograph.id
    expect(subject.parent.children.first.noid).to eq imap.id
  end
end
