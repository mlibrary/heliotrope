require 'spec_helper'

# Spot checking a few pages to ensure that the stylesheet is rendered correctly in browser.
describe 'HTML page rendering', js: true do
  it "root page" do
    visit '/catalog/oai'
    expect(page).to have_content 'not a legal OAI-PMH verb'
  end

  it "identify page" do
    visit '/catalog/oai?verb=Identify'
    expect(page).to have_xpath('//td[text()="Earliest Datestamp"]/parent::*/td[@class="value"]', text: '2014-02-03T18:42:53Z')
  end

  it "lists records" do
    visit '/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc'
    expect(page).to have_content('OAI Record: oai:test:00282214')
  end

  it "document page" do
    visit '/catalog/oai?verb=GetRecord&identifier=oai:test:00282214&metadataPrefix=oai_dc'
    expect(page).to have_xpath('//td[text()="Title"]/parent::*/td[@class="value"]', text: 'Fikr-i Ayāz')
  end

  it "lists verb on page" do
    visit '/catalog/oai?verb=Identify'
    expect(page).to have_content('Request was of type Identify.')
  end

  it "lists metadata formats for record" do
    visit '/catalog/oai?verb=ListMetadataFormats&identifier=oai:test:00282214'
    expect(page).to have_content('This is a list of metadata formats available for the record "oai:test:00282214"')
  end
end
