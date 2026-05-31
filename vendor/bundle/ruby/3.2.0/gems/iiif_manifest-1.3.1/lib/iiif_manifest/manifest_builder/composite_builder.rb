module IIIFManifest
  class ManifestBuilder
    class CompositeBuilder
      attr_reader :services
      delegate :length, to: :services
      def initialize(*services)
        @services = services.compact
      end

      def apply(manifest)
        services.each do |service|
          manifest = service.apply(manifest)
        end
        manifest
      end

      def method_missing(meth_name, *args, &block)
        services.map do |service|
          service.__send__(meth_name, *args, &block)
        end
      end
    end
  end
end
