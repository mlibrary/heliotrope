require 'rails_helper'

class TestWork < ActiveFedora::Base
  include StoresCreatorNameSeparately
end

describe StoresCreatorNameSeparately do
  let(:attributes) { {} }
  let(:work) { TestWork.new(attributes) }

  subject { work }

  it 'has properties for creator first and last name' do
    expect(subject.creator_family_name).to be_nil
    expect(subject.creator_given_name).to be_nil
  end

  describe '#to_solr' do
    let(:attributes) {{ creator_family_name: 'Shakespeare',
                        creator_given_name: 'W.' }}
    subject { work.to_solr }

    it 'indexes the full name of the creator' do
      expect(subject['creator_full_name_tesim']).to eq 'Shakespeare, W.'
      expect(subject['creator_full_name_sim']).to eq 'Shakespeare, W.'
    end
  end
end
