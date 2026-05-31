require 'rdf/ldp/spec/resource'

shared_examples 'a NonRDFSource' do
  it_behaves_like 'a Resource'

  subject { described_class.new(uri) }
  let(:uri) { RDF::URI 'http://example.org/moomin' }

  let(:contents) { StringIO.new('mummi') }

  after { subject.destroy }

  describe '#non_rdf_source?' do
    it { is_expected.to be_non_rdf_source }
  end

  describe '#create' do
    it 'writes the input to body' do
      subject.create(contents, 'text/plain')
      contents.rewind
      expect(subject.to_response.each.to_a).to eq contents.each.to_a
    end

    it 'sets #content_type' do
      expect { subject.create(StringIO.new(''), 'text/plain') }
        .to change { subject.content_type }.to('text/plain')
    end

    it 'persists to resource' do
      repo = RDF::Repository.new
      saved = described_class.new(uri, repo)

      saved.create(contents, 'text/plain')
      contents.rewind

      loaded = RDF::LDP::Resource.find(uri, repo)
      expect(loaded.to_response.each.to_a).to eq contents.each.to_a
    end

    it 'creates an LDP::RDFSource' do
      repo = RDF::Repository.new
      saved = described_class.new(uri, repo)
      description = RDF::LDP::RDFSource.new(subject.description_uri, repo)

      expect { saved.create(contents, 'text/plain') }
        .to change { description.exists? }.from(false).to(true)
    end
  end

  describe '#update' do
    before { subject.create(contents, 'text/plain') }

    it 'writes the input to body' do
      new_contents = StringIO.new('snorkmaiden')
      expect { subject.update(new_contents, 'text/plain') }
        .to change { subject.to_response.to_a }
        .from(a_collection_containing_exactly('mummi'))
        .to(a_collection_containing_exactly('snorkmaiden'))
    end

    it 'updates #content_type' do
      expect { subject.update(contents, 'text/prs.moomin') }
        .to change { subject.content_type }
        .from('text/plain').to('text/prs.moomin')
    end
  end

  describe '#description' do
    it 'is not found' do
      expect { subject.description }.to raise_error RDF::LDP::NotFound
    end

    context 'when it exists' do
      before { subject.create(StringIO.new(''), 'text/plain') }

      it 'is an RDFSource' do
        expect(subject.description).to be_rdf_source
      end

      it 'is the description uri' do
        expect(subject.description.to_uri).to eq subject.description_uri
      end
    end
  end

  describe '#description_uri' do
    it 'is a uri' do
      expect(subject.description_uri).to be_a RDF::URI
    end
  end

  describe '#storage' do
    it 'sets a default storage adapter' do
      expect(subject.storage).to be_a RDF::LDP::NonRDFSource::FileStorageAdapter
    end

    it 'explicitly sets a storage adapter' do
      class DummyAdapter < RDF::LDP::NonRDFSource::FileStorageAdapter
      end

      dummy_subject = described_class.new(uri, nil, DummyAdapter)
      expect(dummy_subject.storage).to be_a DummyAdapter
    end
  end

  describe '#to_response' do
    it 'gives an empty response if it is new' do
      expect(subject.to_response.to_a).to eq []
    end

    it 'does not create a non-existant file' do
      subject.to_response
      expect(subject.storage.send(:file_exists?)).to be false
    end
  end

  describe '#destroy' do
    before { subject.create(contents, 'text/plain') }

    it 'deletes the content' do
      expect { subject.destroy }
        .to change { subject.to_response.to_a }
        .from(a_collection_containing_exactly('mummi')).to([])
    end

    it 'marks resource as destroyed' do
      expect { subject.destroy }
        .to change { subject.destroyed? }.from(false).to(true)
    end
  end

  describe '#content_type' do
    it 'sets and gets a content_type' do
      expect { subject.content_type = 'text/plain' }
        .to change { subject.content_type }.to('text/plain')
    end
  end
end
