require 'spec_helper'

describe Hydra::PCDM::File do
  let(:file)     { described_class.new }
  let(:reloaded) { described_class.new(file.uri) }

  describe 'when saving' do
    it 'sets an RDF type' do
      file.content = 'stuff'
      expect(file.save).to be true
      expect(reloaded.metadata_node.query([nil, RDF.type, Hydra::PCDM::Vocab::PCDMTerms.File]).map(&:object)).to eq [Hydra::PCDM::Vocab::PCDMTerms.File]
    end
  end

  describe '#label' do
    it 'saves a label' do
      file.content = 'stuff'
      file.label = 'foo'
      expect(file.label).to eq ['foo']
      expect(file.save).to be true
      expect(reloaded.label).to eq ['foo']
    end
  end

  describe 'technical metadata' do
    let(:date_created) { Date.parse 'Fri, 08 May 2015 08:00:00 -0400 (EDT)' }
    let(:date_modified) { Date.parse 'Sat, 09 May 2015 09:00:00 -0400 (EDT)' }
    let(:content) { 'hello world' }
    let(:file) { described_class.new.tap { |ds| ds.content = content } }

    it 'handles #file_name' do
      name = 'picture.jpg'
      file.file_name = name
      file.save

      expect(reloaded.file_name).to contain_exactly(name)
    end

    it 'handles #file_size' do
      file.file_size = content.length.to_s
      file.save

      expect(reloaded.file_size).to contain_exactly(content.length.to_s)
    end

    it 'handles #date_created' do
      file.date_created = date_created
      file.save

      expect(reloaded.date_created).to contain_exactly(date_created)
    end

    it 'handles #date_modified' do
      file.date_modified = date_modified
      file.save

      expect(reloaded.date_modified).to contain_exactly(date_modified)
    end

    it 'handles #byte_order' do
      order = 'little-endian'
      file.byte_order = order
      file.save

      expect(reloaded.byte_order).to contain_exactly(order)
    end

    it 'handles #mime_type' do
      ctype = 'application/jpg'
      file.mime_type = ctype
      file.save

      expect(reloaded.mime_type).to eq ctype
    end

    # This may be resolved, as this test is now failing on CircleCI
    xit 'does not save server managed properties' do
      # Currently we can't write this property because Fedora
      # complains that it's a server managed property. This test
      # is mostly to document this situation.
      file.file_hash = 'the-hash'
      expect { file.save }.to raise_error(Ldp::Conflict, %r{Could not remove triple containing predicate http://www.loc.gov/premis/rdf/v1#hasMessageDigest to node .*})
    end
  end

  describe 'with a file that has no type' do
    subject { file.metadata_node.get_values(:type) }
    let(:pcdm_file)   { Hydra::PCDM::Vocab::PCDMTerms.File }
    let(:custom_type) { ::RDF::URI.new('http://example.com/MyType') }

    it 'add a type that already exists' do
      subject << pcdm_file
      expect(subject).to eq [pcdm_file]
    end

    it 'add a custom type' do
      subject << custom_type
      expect(subject).to include custom_type
    end
  end

  describe '::metadata_class_factory' do
    subject { described_class.metadata_class_factory }
    it { is_expected.to eq(ActiveFedora::WithMetadata::DefaultMetadataClassFactory) }
  end
end
