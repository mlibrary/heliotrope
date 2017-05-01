require 'rails_helper'

class TestWork < ActiveFedora::Base
  include StoresCreatorNameSeparately
end

describe StoresCreatorNameSeparately do
  let(:attributes) { {} }
  let(:work) { TestWork.new(attributes) }

  subject { work }

  it 'has properties for creator first and last names' do
    expect(subject.creator_family_name).to be_nil
    expect(subject.creator_given_name).to be_nil
  end

  describe '#to_solr' do
    let(:attributes) {{ creator_family_name: 'Moose',
                        creator_given_name: 'Bullwinkle' }}
    subject { work.to_solr }

    it 'indexes the full name of the creator' do
      expect(subject['creator_full_name_tesim']).to eq 'Moose, Bullwinkle'
      expect(subject['creator_full_name_sim']).to eq 'Moose, Bullwinkle'
    end
  end
end
