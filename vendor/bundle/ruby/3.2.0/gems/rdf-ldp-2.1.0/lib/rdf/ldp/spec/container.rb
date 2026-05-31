require 'rdf/ldp/spec/rdf_source'

shared_examples 'a Container' do
  it_behaves_like 'an RDFSource'

  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new(uri) }

  it { is_expected.to be_container }

  describe '#container_class' do
    it 'returns a uri' do
      expect(subject.container_class).to be_a RDF::URI
    end
  end

  describe '#containment_triples' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns a uri' do
      subject.add_containment_triple(resource)
      expect(subject.containment_triples)
        .to contain_exactly(an_instance_of(RDF::Statement))
    end
  end

  describe '#add' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }
    before { subject.create(StringIO.new, 'application/n-triples') }

    it 'returns self' do
      expect(subject.add(resource)).to eq subject
    end

    it 'containment triple is added to graph' do
      expect(subject.add(resource).graph)
        .to include subject.make_containment_triple(resource)
    end
  end

  describe '#add_containment_triple' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns self' do
      expect(subject.add_containment_triple(resource)).to eq subject
    end

    it 'containment triple is added to graph' do
      expect(subject.add_containment_triple(resource).graph)
        .to include subject.make_containment_triple(resource)
    end
  end

  describe '#remove_containment_triple' do
    before { subject.add_containment_triple(resource) }

    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns self' do
      expect(subject.remove_containment_triple(resource)).to eq subject
    end

    it 'membership triple is added to graph' do
      expect(subject.remove_containment_triple(resource).graph)
        .not_to include subject.make_containment_triple(resource)
    end

    it 'updates last_modified for container' do
      expect { subject.remove_containment_triple(resource) }
        .to change { subject.last_modified }
    end

    it 'updates etag for container' do
      expect { subject.remove_containment_triple(resource) }
        .to change { subject.etag }
    end
  end

  describe '#make_containment_triple' do
    let(:resource) { uri / 'papa' }

    it 'returns a statement' do
      expect(subject.make_containment_triple(resource)).to be_a RDF::Statement
    end

    it 'statement subject *or* object is #subject_uri' do
      sub = subject.make_containment_triple(resource).subject
      obj = subject.make_containment_triple(resource).object
      expect([sub, obj]).to include subject.subject_uri
    end

    it 'converts Resource classes to URI' do
      sub = subject.make_containment_triple(subject).subject
      obj = subject.make_containment_triple(subject).object
      expect([sub, obj]).to include subject.subject_uri
    end
  end

  describe '#request' do
    let(:graph) { RDF::Graph.new }

    let(:env) do
      { 'rack.input' => StringIO.new(graph.dump(:ntriples)),
        'CONTENT_TYPE' => 'application/n-triples' }
    end

    let(:statement) do
      RDF::Statement(subject.subject_uri,
                     RDF::Vocab::LDP.contains,
                     'moomin')
    end

    context 'with :PATCH',
            if: described_class.private_method_defined?(:patch) do

      it 'raises conflict error when editing containment triples' do
        patch_statement = statement.clone
        patch_statement.object = 'snorkmaiden'
        patch = '@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .' \
                "\n\nAdd { #{statement.subject.to_base} " \
                "#{statement.predicate.to_base} #{statement.object.to_base} } ."
        env = { 'CONTENT_TYPE' => 'text/ldpatch',
                'rack.input'   => StringIO.new(patch) }

        expect { subject.request(:patch, 200, {}, env) }
          .to raise_error RDF::LDP::Conflict
      end
    end

    context 'with :PUT',
            if: described_class.private_method_defined?(:put) do
      context 'when PUTing containment triples' do
        it 'when creating a resource raises a Conflict error' do
          graph << statement

          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'when resource exists raises a Conflict error' do
          subject.create(StringIO.new, 'application/n-triples')
          graph << statement
          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'can put existing containment triple' do
          subject.create(StringIO.new, 'application/n-triples')
          subject.graph << statement
          graph << statement
          expect(subject.request(:PUT, 200, { 'abc' => 'def' }, env).first)
            .to eq 200
        end

        it 'writes data when putting existing containment triple' do
          subject.create(StringIO.new, 'application/n-triples')
          subject.graph << statement
          graph << statement

          new_st = RDF::Statement(RDF::URI('http://example.org/new_moomin'),
                                  RDF::Vocab::DC.title,
                                  'moomin')
          graph << new_st
          expect(subject.request(:PUT, 200, { 'abc' => 'def' }, env).last.graph)
            .to have_statement new_st
        end

        it 'raises conflict error when without existing containment triples' do
          subject.create(StringIO.new, 'application/n-triples')
          subject.graph << statement
          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to raise_error RDF::LDP::Conflict
        end
      end
    end

    context 'when POST is implemented',
            if: described_class.private_method_defined?(:post) do
      let(:graph) { RDF::Graph.new }
      before { subject.create(StringIO.new, 'application/n-triples') }

      let(:env) do
        { 'rack.input' => StringIO.new(graph.dump(:ntriples)),
          'CONTENT_TYPE' => 'application/n-triples' }
      end

      it 'returns status 201' do
        expect(subject.request(:POST, 200, {}, env).first).to eq 201
      end

      it 'gives created resource as body' do
        expect(subject.request(:POST, 200, {}, env).last)
          .to be_a RDF::LDP::Resource
      end

      it 'generates an id' do
        expect(subject.request(:POST, 200, {}, env).last.subject_uri)
          .to be_starts_with subject.subject_uri.to_s
      end

      it 'adds containment statement to resource' do
        expect { subject.request(:POST, 200, {}, env) }
          .to change { subject.containment_triples.count }.from(0).to(1)
      end

      it 'updates last_modified for container' do
        expect { subject.request(:POST, 200, {}, env) }
          .to change { subject.last_modified }
      end

      it 'updates etag for container' do
        expect { subject.request(:POST, 200, {}, env) }
          .to change { subject.etag }
      end

      context 'with Container interaction model' do
        it 'creates a basic container' do
          env['HTTP_LINK'] = "<#{RDF::LDP::Container.to_uri}>;rel=\"type\""
          expect(subject.request(:POST, 200, {}, env).last)
            .to be_a RDF::LDP::Container
        end

        context 'BasicContainer' do
          it 'creates a basic container' do
            env['HTTP_LINK'] =
              '<http://www.w3.org/ns/ldp#BasicContainer>;rel="type"'
            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::Container
          end
        end

        context 'DirectContainer' do
          it 'creates a direct container' do
            env['HTTP_LINK'] =
              "<#{RDF::LDP::DirectContainer.to_uri}>;rel=\"type\""

            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::DirectContainer
          end
        end

        context 'IndirectContainer' do
          it 'creates a indirect container' do
            env['HTTP_LINK'] =
              "<#{RDF::LDP::IndirectContainer.to_uri}>;rel=\"type\""

            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::IndirectContainer
          end
        end
      end

      context 'with a Slug' do
        it 'creates resource with Slug' do
          env['HTTP_SLUG'] = 'snork'
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to eq subject.subject_uri / env['HTTP_SLUG']
        end

        it 'mints a uri when empty Slug is given' do
          env['HTTP_SLUG'] = ''
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to be_starts_with subject.subject_uri
        end

        it 'raises a 409 Conflict when slug is already taken' do
          env['HTTP_SLUG'] = 'snork'
          subject.request(:POST, 200, {}, env)

          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'raises a 409 Conflict when slug is already taken but destroyed' do
          env['HTTP_SLUG'] = 'snork'
          created = subject.request(:POST, 200, {}, env).last
          allow(created).to receive(:destroyed?).and_return true

          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'raises a 406 NotAcceptable if slug has a uri fragment `#`' do
          env['HTTP_SLUG'] = 'snork#maiden'

          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::NotAcceptable
        end

        it 'url-encodes Slug' do
          env['HTTP_SLUG'] = 'snork maiden'
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to eq subject.subject_uri / 'snork%20maiden'
        end
      end

      context 'with graph content' do
        before do
          graph << RDF::Statement(uri, RDF::Vocab::DC.title, 'moomin')
          graph << RDF::Statement(RDF::Node.new, RDF::Vocab::DC.creator, 'tove')
          graph <<
            RDF::Statement(RDF::Node.new, RDF.type, RDF::Vocab::FOAF.Person)
        end

        it 'parses graph into created resource' do
          expect(subject.request(:POST, 200, {}, env).last.to_response)
            .to be_isomorphic_with graph
        end

        it 'adds a Location header' do
          expect(subject.request(:POST, 200, {}, env)[1]['Location'])
            .to start_with subject.subject_uri.to_s
        end

        context 'with quads' do
          let(:graph) do
            RDF::Graph.new(graph_name: subject.subject_uri,
                           data: RDF::Repository.new)
          end

          let(:env) do
            { 'rack.input' => StringIO.new(graph.dump(:nquads)),
              'CONTENT_TYPE' => 'application/n-quads' }
          end

          it 'parses graph into created resource without regard for context' do
            context_free_graph = RDF::Graph.new
            context_free_graph << graph.statements

            expect(subject.request(:POST, 200, {}, env).last.to_response)
              .to be_isomorphic_with context_free_graph
          end
        end
      end
    end
  end
end
