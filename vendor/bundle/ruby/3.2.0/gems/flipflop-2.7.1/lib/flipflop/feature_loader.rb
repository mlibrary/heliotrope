module Flipflop
  class FeatureLoader
    @@lock = Monitor.new

    class << self
      def current
        @current or @@lock.synchronize { @current ||= new }
      end

      private :new
    end

    extend Forwardable
    delegate [:execute, :updated?] => :checker

    def initialize
      @paths = []
    end

    def append(engine)
      @paths.concat(engine.paths.add("config/features.rb".freeze).existent)
    end

    private

    def checker
      @checker or @@lock.synchronize do
        @checker ||= ActiveSupport::FileUpdateChecker.new(@paths) { reload! }
      end
    end

    def reload!
      @@lock.synchronize do
        Flipflop::FeatureSet.current.replace do
          @paths.each { |path| Kernel.load(path) }
        end
      end
    end
  end
end
