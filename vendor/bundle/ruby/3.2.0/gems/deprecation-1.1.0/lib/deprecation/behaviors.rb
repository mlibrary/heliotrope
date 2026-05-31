require "active_support/notifications"
require "active_support/concern"

module Deprecation

  class <<self
    attr_accessor :default_deprecation_behavior
  end

    self.default_deprecation_behavior = :stderr

    # Returns the current behavior or if one isn't set, defaults to +:stderr+
    def deprecation_behavior
      @deprecation_behavior ||= [Deprecation.behaviors(self)[Deprecation.default_deprecation_behavior]]
    end

    # Sets the behavior to the specified value. Can be a single value, array, or
    # an object that responds to +call+.
    #
    # Available behaviors:
    #
    # [+stderr+]  Log all deprecation warnings to +$stderr+.
    # [+log+]     Log all deprecation warnings to +Rails.logger+.
    # [+notify]   Use +ActiveSupport::Notifications+ to notify +deprecation.rails+.
    # [+silence+] Do nothing.
    #
    # Setting behaviors only affects deprecations that happen after boot time.
    # Deprecation warnings raised by gems are not affected by this setting because
    # they happen before Rails boots up.
    #
    #   Deprecation.deprecation_behavior = :stderr
    #   Deprecation.deprecation_behavior = [:stderr, :log]
    #   Deprecation.deprecation_behavior = MyCustomHandler
    #   Deprecation.deprecation_behavior = proc { |message, callstack| 
    #     # custom stuff
    #   }
    def deprecation_behavior=(deprecation_behavior)
      @deprecation_behavior = Array(deprecation_behavior).map { |b| Deprecation.behaviors(self)[b] || b }
    end

  def self.deprecations
    @deprecations ||= {}
  end

    def self.behaviors klass
  # Default warning behaviors per Rails.env.
  {
    :stderr => Proc.new { |message, callstack|
       $stderr.puts(message)
       $stderr.puts callstack.join("\n  ") if klass.respond_to? :debug and klass.debug
     },
    :log => Proc.new { |message, callstack|
       logger = Deprecation.logger
       logger.warn message
       logger.debug callstack.join("\n  ") if klass.respond_to? :debug and klass.debug
     },
     :notify => Proc.new { |message, callstack|
        ActiveSupport::Notifications.instrument("deprecation.#{klass.to_s}",
        :message => message, :callstack => callstack)
     },
     :raise => Proc.new { |message, callstack| raise message },
     :silence => Proc.new { |message, callstack| },
     :test => Proc.new do |message, callstack| 
        hash = message.hash + callstack[0..2].join("\n").hash
        unless self.deprecations[hash]
          self.deprecations[hash] = { message: message, callstack: callstack, count: 1 }
        else
          self.deprecations[hash][:count] += 1
        end
      end,
     :stderr_report => Proc.new do |message, callstack|
        hash = message.hash + callstack[0..2].join("\n").hash
        unless self.deprecations[hash]
          self.deprecations[hash] = { message: message, callstack: callstack, count: 1 }
          $stderr.puts(message)
          $stderr.puts callstack.join("\n  ") if klass.respond_to? :debug and klass.debug
        else
          self.deprecations[hash][:count] += 1
        end
      end
  }
    end
end
