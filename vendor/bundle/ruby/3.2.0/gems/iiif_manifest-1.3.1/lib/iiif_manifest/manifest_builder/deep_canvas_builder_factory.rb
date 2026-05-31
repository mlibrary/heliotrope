module IIIFManifest
  class ManifestBuilder
    class DeepCanvasBuilderFactory < CanvasBuilderFactory
      private

      def file_set_presenters(work)
        DeepFileSetEnumerator.new(work).to_a
      end
    end

    class DeepFileSetEnumerator
      attr_reader :work
      include Enumerable
      def initialize(work)
        @work = work
      end

      def each(&block)
        file_set_presenters.each do |file_set_presenter|
          yield file_set_presenter
        end
        work_presenters.each do |work_presenter|
          self.class.new(work_presenter).each(&block)
        end
      end

      private

      def file_set_presenters
        work.try(:file_set_presenters) || []
      end

      def work_presenters
        work.try(:work_presenters) || []
      end
    end
  end
end
