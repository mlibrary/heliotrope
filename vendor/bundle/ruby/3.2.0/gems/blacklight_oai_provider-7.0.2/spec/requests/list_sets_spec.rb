require "spec_helper"

RSpec.describe 'OAI-PMH ListSets Request' do
  let(:xml) { Nokogiri::XML(response.body) }
  let(:namespaces) do
    {
      dc: 'http://purl.org/dc/elements/1.1/',
      xmlns: 'http://www.openarchives.org/OAI/2.0/',
      oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    }
  end
  let(:test_oai_config) { {} }
  let(:old_config) { CatalogController.new.oai_config }

  before do
    old_config
    CatalogController.configure_blacklight do |config|
      config.oai = test_oai_config
    end
  end

  after do
    CatalogController.configure_blacklight do |config|
      config.oai = old_config
    end
  end

  context 'without set configuration' do
    it 'shows that no sets exist' do
      get oai_catalog_path(verb: 'ListSets')
      expect(xml.xpath('//xmlns:error').text).to eql 'This repository does not support sets.'
    end
  end

  context 'with set configuration' do
    let(:test_oai_config) { old_config }

    it 'shows all sets' do
      get oai_catalog_path(verb: 'ListSets')
      expect(xml.xpath('//xmlns:set').count).to be 12
    end

    it 'contains english set' do
      get oai_catalog_path(verb: 'ListSets')
      expect(xml.xpath('//xmlns:set//xmlns:setSpec').map(&:text)).to include 'language:English'
      expect(xml.xpath('//xmlns:set//xmlns:setName').map(&:text)).to include 'Language: English'
    end

    it 'shows the correct verb' do
      get oai_catalog_path(verb: 'ListSets')
      expect(xml.at_xpath('//xmlns:request').attribute('verb').value).to eql 'ListSets'
    end
  end

  context 'when set configuration contains description' do
    let(:test_oai_config) do
      {
        document: {
          set_fields: [
            { label: 'subject', solr_field: 'subject_ssim',
              description: "Subject topic set using FAST subjects" }
          ]
        }
      }
    end

    it 'shows set description' do
      get oai_catalog_path(verb: 'ListSets')
      expect(
        xml.at_xpath('//xmlns:set/xmlns:setDescription/oai_dc:dc/dc:description', namespaces).text
      ).to eql 'Subject topic set using FAST subjects'
    end
  end

  context 'when custom set model is provided' do
    let(:test_oai_config) do
      stub_const 'ChangeDescriptionSet', custom_set_model

      {
        document: {
          set_model: ChangeDescriptionSet,
          set_fields: [{ solr_field: 'format' }]
        }
      }
    end
    let(:custom_set_model) do
      Class.new(BlacklightOaiProvider::SolrSet) do
        def description
          "This is a #{label} set containing records with the value of #{value}."
        end
      end
    end

    it "shows correct description" do
      get oai_catalog_path(verb: 'ListSets')
      expect(
        xml.at_xpath('//xmlns:set/xmlns:setDescription/oai_dc:dc/dc:description', namespaces).text
      ).to eql 'This is a format set containing records with the value of Book.'
    end
  end
end
