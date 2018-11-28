# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CitationsBehaviors::NameBehavior do
  let(:title_behavior) { described_class.new }

  # https://tools.lib.umich.edu/jira/browse/HELIO-2319

  it 'gets given_name_first(Flavigny) as Flavigny' do
    expect(given_name_first('Flavigny')).to eq 'Flavigny'
  end

  it 'gets surname_first(Flavigny) as Flavigny' do
    expect(surname_first('Flavigny')).to eq 'Flavigny'
  end

  it 'gets abbreviate_name(Flavigny) as Flavigny' do
    expect(abbreviate_name('Flavigny')).to eq 'Flavigny'
  end

  # The following are just sanity checks in case I broke existing behavior,
  # and since Hyrax seems to have no actual tests for the citation code.

  it 'gets given_name_first(John Dvorak) as John Dvorak' do
    expect(given_name_first('John Dvorak')).to eq 'John Dvorak'
  end

  it 'gets surname_first(John Dvorak) as Dvorak, John' do
    expect(surname_first('John Dvorak')).to eq 'Dvorak, John'
  end

  it 'gets abbreviate_name(John Dvorak) as Dvorak, J.' do
    expect(abbreviate_name('John Dvorak')).to eq 'Dvorak, J.'
  end

  it 'gets given_name_first(J. Dvorak) as J. Dvorak' do
    expect(given_name_first('J. Dvorak')).to eq 'J. Dvorak'
  end

  it 'gets surname_first(J. Dvorak) as Dvorak, J.' do
    expect(surname_first('J. Dvorak')).to eq 'Dvorak, J.'
  end

  it 'gets abbreviate_name(J. Dvorak) as Dvorak, J.' do
    expect(abbreviate_name('J. Dvorak')).to eq 'Dvorak, J.'
  end
end
