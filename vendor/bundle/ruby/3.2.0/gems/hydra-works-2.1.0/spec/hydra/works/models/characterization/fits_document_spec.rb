require 'spec_helper'

describe Hydra::Works::Characterization::FitsDocument do
  it 'defines an xml template' do
    templ = described_class.xml_template.remove_namespaces!
    expect(templ.xpath('/fits/identification/identity/@toolname').first.value).to eq('FITS')
  end
end
