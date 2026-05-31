module IIIFManifest
  class ManifestBuilder
    class CompositeBuilderFactory
      attr_reader :factories, :composite_builder
      def initialize(*factories, composite_builder:)
        @factories = factories
        @composite_builder = composite_builder
      end

      def new(*args)
        result = factories.map do |factory|
          factory.new(*args)
        end
        composite_builder.new(*result)
      end
    end
  end
end
