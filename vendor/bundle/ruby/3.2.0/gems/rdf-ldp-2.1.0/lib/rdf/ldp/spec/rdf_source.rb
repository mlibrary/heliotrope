require 'rdf/ldp/spec/resource'

shared_examples 'an RDFSource' do
  it_behaves_like 'a Resource'

  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new('http://ex.org/moomin') }
  it { is_expected.to be_rdf_source }
  it { is_expected.not_to be_non_rdf_source }

  describe '#parse_graph' do
    it 'raises UnsupportedMediaType if no reader found' do
      expect { subject.send(:parse_graph, StringIO.new('graph'), 'text/fake') }
        .to raise_error RDF::LDP::UnsupportedMediaType
    end

    it 'raises BadRequest if graph cannot be parsed' do
      expect do
        subject.send(:parse_graph,
                     StringIO.new('graph'),
                     'application/n-triples')
      end.to raise_error RDF::LDP::BadRequest
    end

    describe 'parsing the graph' do
      let(:graph) { RDF::Repository.new }

      before do
        graph << RDF::Statement(RDF::URI('http://ex.org/moomin'),
                                RDF.type,
                                RDF::Vocab::FOAF.Person,
                                graph_name: subject.subject_uri)

        10.times do
          graph << RDF::Statement(RDF::Node.new,
                                  RDF::Vocab::DC.creator,
                                  RDF::Node.new,
                                  graph_name: subject.subject_uri)
        end
      end

      it 'parses turtle' do
        expect(subject.send(:parse_graph,
                            StringIO.new(graph.dump(:ttl)),
                            'text/turtle'))
          .to be_isomorphic_with graph
      end

      it 'parses ntriples' do
        expect(subject.send(:parse_graph,
                            StringIO.new(graph.dump(:ntriples)),
                            'application/n-triples'))
          .to be_isomorphic_with graph
      end
    end
  end

  describe '#etag' do
    before do
      subject.graph << statement
      other.graph << statement
    end

    let(:other) { described_class.new(RDF::URI('http://ex.org/blah')) }

    let(:statement) do
      RDF::Statement(RDF::URI('http://ex.org/m'),
                     RDF::Vocab::DC.title,
                     'moomin')
    end

    it 'is the same for equal graphs' do
      expect(subject.etag).to eq other.etag
    end

    xit 'is different for different graphs' do
      subject.graph <<
        RDF::Statement(RDF::Node.new, RDF::Vocab::DC.title, 'mymble')
      expect(subject.etag).not_to eq other.etag
    end
  end

  describe '#create' do
    let(:subject) { described_class.new(RDF::URI('http://ex.org/m')) }
    let(:graph) { RDF::Graph.new }

    it 'does not create when graph fails to parse' do
      begin
        subject.create(StringIO.new(graph.dump(:ttl)), 'text/moomin')
      rescue; end

      expect(subject).not_to exist
    end

    it 'returns itself' do
      expect(subject.create(StringIO.new(graph.dump(:ttl)), 'text/turtle'))
        .to eq subject
    end

    it 'yields a transaction' do
      expect do |b|
        subject.create(StringIO.new(graph.dump(:ttl)), 'text/turtle', &b)
      end.to yield_with_args(be_kind_of(RDF::Transaction))
    end

    it 'interprets NULL URI as this resource' do
      graph << RDF::Statement(RDF::URI.new, RDF::Vocab::DC.title, 'moomin')

      created =
        subject.create(StringIO.new(graph.dump(:ttl)), 'text/turtle').graph

      expect(created)
        .to have_statement RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::DC.title,
                                          'moomin')
    end

    it 'interprets Relative URIs as this based on this resource' do
      graph << RDF::Statement(subject.subject_uri,
                              RDF::Vocab::DC.isPartOf,
                              RDF::URI('#moomin'))

      created =
        subject.create(StringIO.new(graph.dump(:ttl)), 'text/turtle').graph

      expect(created)
        .to have_statement RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::DC.isPartOf,
                                          subject.subject_uri / '#moomin')
    end
  end

  describe '#update' do
    let(:statement) do
      RDF::Statement(subject.subject_uri, RDF::Vocab::DC.title, 'moomin')
    end

    let(:graph) { RDF::Graph.new << statement }
    let(:content_type) { 'text/turtle' }

    shared_examples 'updating rdf_sources' do
      it 'changes the response' do
        expect { subject.update(StringIO.new(graph.dump(:ttl)), content_type) }
          .to change { subject.to_response }
      end

      it 'changes etag' do
        expect { subject.update(StringIO.new(graph.dump(:ttl)), content_type) }
          .to change { subject.etag }
      end

      it 'yields a transaction' do
        expect do |b|
          subject.update(StringIO.new(graph.dump(:ttl)), content_type, &b)
        end.to yield_with_args(be_kind_of(RDF::Transaction))
      end

      context 'with bad media type' do
        it 'raises UnsupportedMediaType' do
          graph_io = StringIO.new(graph.dump(:ttl))

          expect { subject.update(graph_io, 'text/moomin') }
            .to raise_error RDF::LDP::UnsupportedMediaType
        end

        it 'does not update #last_modified' do
          modified = subject.last_modified
          begin
            subject.update(StringIO.new(graph.dump(:ttl)), 'text/moomin')
          rescue; end

          expect(subject.last_modified).to eq modified
        end
      end
    end

    include_examples 'updating rdf_sources'

    context 'when it exists' do
      before { subject.create(StringIO.new, 'application/n-triples') }

      include_examples 'updating rdf_sources'
    end
  end

  describe '#patch' do
    it 'raises UnsupportedMediaType when no media type is given' do
      expect { subject.request(:patch, 200, {}, {}) }
        .to raise_error RDF::LDP::UnsupportedMediaType
    end

    it 'gives PreconditionFailed when trying to update with wrong Etag' do
      env = { 'HTTP_IF_MATCH' => 'not an Etag' }
      expect { subject.request(:PATCH, 200, { 'abc' => 'def' }, env) }
        .to raise_error RDF::LDP::PreconditionFailed
    end

    context 'ldpatch' do
      it 'raises BadRequest when invalid document' do
        env = { 'CONTENT_TYPE' => 'text/ldpatch',
                'rack.input'   => StringIO.new('---invalid---') }
        expect { subject.request(:patch, 200, {}, env) }
          .to raise_error RDF::LDP::BadRequest
      end

      it 'handles patch' do
        statement =
          RDF::Statement(subject.subject_uri, RDF::Vocab::FOAF.name, 'Moomin')
        patch = '@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .' \
                "\n\nAdd { #{statement.subject.to_base} " \
                "#{statement.predicate.to_base} #{statement.object.to_base} } ."
        env = { 'CONTENT_TYPE' => 'text/ldpatch',
                'rack.input'   => StringIO.new(patch) }

        expect { subject.request(:patch, 200, {}, env) }
          .to change { subject.graph.statements.to_a }
          .to(contain_exactly(statement))
      end
    end

    context 'sparql update' do
      it 'raises BadRequest when invalid document' do
        env = { 'CONTENT_TYPE' => 'application/sparql-update',
                'rack.input'   => StringIO.new('---invalid---') }

        expect { subject.request(:patch, 200, {}, env) }
          .to raise_error RDF::LDP::BadRequest
      end

      it 'runs sparql update' do
        update = "INSERT DATA { #{subject.subject_uri.to_base} "\
                 "#{RDF::Vocab::DC.title.to_base} 'moomin' . }"

        env = { 'CONTENT_TYPE' => 'application/sparql-update',
                'rack.input'   => StringIO.new(update) }

        expect { subject.request(:patch, 200, {}, env) }
          .to change { subject.graph.count }.from(0).to(1)
      end
    end
  end

  describe '#graph' do
    it 'has a graph' do
      expect(subject.graph).to be_a RDF::Enumerable
    end
  end

  describe '#subject_uri' do
    let(:uri) { RDF::URI('http://ex.org/moomin') }

    it 'has a uri getter' do
      expect(subject.subject_uri).to eq uri
    end

    it 'aliases to #to_uri' do
      expect(subject.to_uri).to eq uri
    end
  end

  describe '#to_response' do
    it 'gives the graph minus context' do
      expect(subject.to_response.graph_name).to eq nil
    end
  end

  describe '#request' do
    context 'with :GET' do
      it 'gives the subject' do
        expect(subject.request(:GET, 200, { 'abc' => 'def' }, {}))
          .to contain_exactly(200, a_hash_including('abc' => 'def'), subject)
      end

      it 'does not call the graph' do
        expect(subject).not_to receive(:graph)
        subject.request(:GET, 200, { 'abc' => 'def' }, {})
      end

      it 'returns 410 GONE when destroyed' do
        allow(subject).to receive(:destroyed?).and_return true
        expect { subject.request(:GET, 200, { 'abc' => 'def' }, {}) }
          .to raise_error RDF::LDP::Gone
      end
    end

    context 'with :DELETE' do
      before { subject.create(StringIO.new, 'application/n-triples') }

      it 'returns 204' do
        expect(subject.request(:DELETE, 200, {}, {}).first).to eq 204
      end

      it 'returns an empty body' do
        expect(subject.request(:DELETE, 200, {}, {}).last)
          .to be_empty
      end

      it 'marks resource as destroyed' do
        expect { subject.request(:DELETE, 200, {}, {}) }
          .to change { subject.destroyed? }.from(false).to(true)
      end
    end

    context 'with :PUT',
            if: described_class.private_method_defined?(:put) do
      let(:graph) { RDF::Graph.new }
      let(:env) do
        { 'rack.input' => StringIO.new(graph.dump(:ntriples)),
          'CONTENT_TYPE' => 'application/n-triples' }
      end

      it 'creates the resource' do
        expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
          .to change { subject.exists? }.from(false).to(true)
      end

      it 'responds 201' do
        expect(subject.request(:PUT, 200, { 'abc' => 'def' }, env).first)
          .to eq 201
      end

      it 'returns the etag' do
        expect(subject.request(:PUT, 200, { 'abc' => 'def' }, env)[1]['ETag'])
          .to eq subject.etag
      end

      context 'when subject exists' do
        before { subject.create(StringIO.new, 'application/n-triples') }

        it 'responds 200' do
          expect(subject.request(:PUT, 200, { 'abc' => 'def' }, env))
            .to contain_exactly(200, a_hash_including('abc' => 'def'), subject)
        end

        it 'replaces the graph with the input' do
          graph <<
            RDF::Statement(subject.subject_uri, RDF::Vocab::DC.title, 'moomin')
          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to change { subject.graph.statements.count }.to(1)
        end

        it 'updates the etag' do
          graph <<
            RDF::Statement(subject.subject_uri, RDF::Vocab::DC.title, 'moomin')
          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to change { subject.etag }
        end

        it 'returns the etag' do
          expect(subject.request(:PUT, 200, { 'abc' => 'def' }, env)[1]['ETag'])
            .to eq subject.etag
        end

        it 'gives PreconditionFailed when trying to update with wrong Etag' do
          env['HTTP_IF_MATCH'] = 'not an Etag'
          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to raise_error RDF::LDP::PreconditionFailed
        end

        it 'succeeds when giving correct Etag' do
          graph <<
            RDF::Statement(subject.subject_uri, RDF::Vocab::DC.title, 'moomin')
          env['HTTP_IF_MATCH'] = subject.etag
          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to change { subject.graph.statements.count }
        end
      end
    end
  end
end
