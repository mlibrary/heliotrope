module IIIFManifest
  class ManifestFactory
    class << self
      def new(work, manifest_service_locator: ManifestServiceLocator)
        super(manifest_service_locator).new(work)
      end
    end

    delegate :collection_manifest_builder, :manifest_builder, :sammelband_manifest_builder,
             to: :manifest_service_locator
    attr_reader :manifest_service_locator

    def initialize(manifest_service_locator)
      @manifest_service_locator = manifest_service_locator
    end

    def new(work)
      if !work.work_presenters.empty?
        if sammelband?(work) || !work.file_set_presenters.empty?
          sammelband_manifest_builder.new(work)
        elsif work.file_set_presenters.empty?
          work = IIIFCollection.new(work)
          collection_manifest_builder.new(work)
        end
      else
        manifest_builder.new(work)
      end
    end

    private

    def sammelband?(work)
      work.respond_to?(:sammelband?) && work.sammelband?
    end
  end
end
