module IIIFManifest
  class ManifestBuilder
    class ChildManifestBuilderFactory
      attr_reader :child_manifest_builder, :composite_builder
      def initialize(child_manifest_builder:, composite_builder:)
        @child_manifest_builder = child_manifest_builder
        @composite_builder = composite_builder
      end

      def new(work)
        composite_builder.new(
          *work.work_presenters.map do |work_presenter|
            child_manifest_builder.new(work_presenter)
          end
        )
      end
    end
  end
end
