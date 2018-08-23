# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CitationsBehaviors::TitleBehavior do
  let(:title_behavior) { described_class.new }

  # https://tools.lib.umich.edu/jira/browse/HELIO-1991

  it 'gets World War II right for Chicago' do
    expect(chicago_citation_title('World War II')).to eq 'World War II'
  end

  it 'gets Circum-Caribbean right for Chicago' do
    expect(chicago_citation_title('Circum-Caribbean adventure')).to eq 'Circum-Caribbean Adventure'
  end

  it 'gets quotes right for Chicago' do
    expect(chicago_citation_title('The Name "Haydn" In Quotes')).to eq 'The Name "Haydn" In Quotes'
  end

  it 'gets World War II right for MLA' do
    expect(mla_citation_title('World War II')).to eq 'World War II'
  end

  it 'gets Circum-Caribbean right for MLA' do
    expect(mla_citation_title('Circum-Caribbean adventure')).to eq 'Circum-Caribbean Adventure'
  end

  it 'gets quotes right for MLA' do
    expect(mla_citation_title('The Name &quot;Haydn&quot; In Quotes')).to eq 'The Name &quot;Haydn&quot; In Quotes'
  end

  # https://tools.lib.umich.edu/jira/browse/HELIO-2088

  it "chicago_citation_title doesn't error 500 on single non-word hyphens, or remove them" do
    expect(chicago_citation_title('Blah - The Meaning of same: dissections of Blah'))
      .to eq 'Blah - The Meaning of Same: Dissections of Blah'
  end

  it "chicago_citation_title doesn't error 500 on double non-word hyphens, or remove them" do
    expect(chicago_citation_title('Blah -- The Meaning of same: dissections of Blah'))
      .to eq 'Blah -- The Meaning of Same: Dissections of Blah'
  end

  it "mla_citation_title doesn't error 500 on single non-word hyphens, or remove them" do
    expect(mla_citation_title('Blah - The Meaning of same: dissections of Blah'))
      .to eq 'Blah - The Meaning of Same: Dissections of Blah'
  end

  it "mla_citation_title doesn't error 500 on double non-word hyphens, or remove them" do
    expect(mla_citation_title('Blah -- The Meaning of same: dissections of Blah'))
      .to eq 'Blah -- The Meaning of Same: Dissections of Blah'
  end
end
