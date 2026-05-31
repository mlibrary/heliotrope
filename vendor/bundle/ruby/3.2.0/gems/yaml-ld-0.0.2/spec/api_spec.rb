
# coding: utf-8
require_relative 'spec_helper'

describe YAML_LD::API do
  let(:logger) {RDF::Spec.logger}
  before {JSON::LD::Context::PRELOADED.clear}

  context "Test Files" do
    %i(psych).each do |adapter|
      Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'test-files/*-input.*'))) do |filename|
        test = File.basename(filename).sub(/-input\..*$/, '')
        frame = filename.sub(/-input\..*$/, '-frame.yamlld')
        framed = filename.sub(/-input\..*$/, '-framed.yamlld')
        compacted = filename.sub(/-input\..*$/, '-compacted.yamlld')
        context = filename.sub(/-input\..*$/, '-context.yamlld')
        expanded = filename.sub(/-input\..*$/, '-expanded.yamlld')
        ttl = filename.sub(/-input\..*$/, '-rdf.ttl')

        context test do
          around do |example|
            @file = File.open(filename)
            case filename
            when /\.yamlld$/
              @file.define_singleton_method(:content_type) {'application/ld+yaml'}
            when /.jsonld$/
              @file.define_singleton_method(:content_type) {'application/ld+json'}
            end
            if File.exist?(context)
              @ctx_io = File.open(context)
              case context
              when /\.yamlld$/
                @ctx_io.define_singleton_method(:content_type) {'application/ld+yaml'}
              when /.jsonld$/
                @ctx_io.define_singleton_method(:content_type) {'application/ld+json'}
              end
            end
            if File.exist?(frame)
              @frame_io = File.open(frame)
              case frame
              when /\.yamlld$/
                @frame_io.define_singleton_method(:content_type) {'application/ld+yaml'}
              when /.jsonld$/
                @frame_io.define_singleton_method(:content_type) {'application/ld+json'}
              end
            end
            example.run
            @file.close
            @ctx_io.close if @ctx_io
            @frame_io.close if @frame_io
          end

          if File.exist?(expanded)
            it "expands" do
              options = {logger: logger, adapter: adapter}
              options[:expandContext] = @ctx_io if context
              yaml = described_class.expand(@file, **options)
              expect(yaml).to be_a(String)
              expect(yaml).to produce_yamlld(File.read(expanded), logger)
            end
          end

          if File.exist?(compacted) && File.exist?(context)
            it "compacts" do
              yaml = described_class.compact(@file, @ctx_io, adapter: adapter, logger: logger)
              expect(yaml).to be_a(String)
              expect(yaml).to produce_yamlld(File.read(compacted), logger)
            end
          end

          if File.exist?(framed) && File.exist?(frame)
            it "frames" do
              yaml = described_class.frame(@file, @frame_io, adapter: adapter, logger: logger)
              expect(yaml).to be_a(String)
              expect(yaml).to produce_yamlld(File.read(framed), logger)
            end
          end

          it "toRdf" do
            expect(RDF::Repository.load(filename, format: :yamlld, adapter: adapter, logger: logger)).to be_equivalent_graph(RDF::Repository.load(ttl), logger: logger)
          end if File.exist?(ttl)
        end
      end
    end
  end
end
