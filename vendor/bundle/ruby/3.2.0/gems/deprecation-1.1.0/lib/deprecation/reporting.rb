module Deprecation
  ACTIVESUPPORT_CONCERN_REGEX = %r{/lib/active_support/concern.rb}
  IGNORE_REGEX = Regexp.union(ACTIVESUPPORT_CONCERN_REGEX)

  class << self

    attr_accessor :show_full_callstack
    # Outputs a deprecation warning to the output configured by <tt>ActiveSupport::Deprecation.behavior</tt>
    #
    #   Deprecation.warn("something broke!")
    #   # => "DEPRECATION WARNING: something broke! (called from your_code.rb:1)"
    def warn(context, message = nil, callstack = nil)
      return if context.respond_to? :silenced? and context.silenced?

      if callstack.nil?
        callstack = caller
        callstack.shift
      end

      deprecation_message(callstack, message).tap do |m|
        deprecation_behavior(context).each { |b| b.call(m, sanitized_callstack(callstack)) }
      end
    end

    def deprecation_behavior context
      if context.respond_to? :deprecation_behavior
        context.deprecation_behavior 
      else
        [Deprecation.behaviors(self)[Deprecation.default_deprecation_behavior]]
      end
    end

    # Silence deprecation warnings within the block.
    def silence context
      if context.respond_to? :silenced=
        old_silenced, context.silenced = context.silenced, true
      end

      yield
    ensure
      context.silenced = old_silenced if context.respond_to? :silenced=
    end

    def collect(context)
      old_behavior = context.deprecation_behavior
      deprecations = []
      context.deprecation_behavior = Proc.new do |message, callstack|
        deprecations << message
      end
      result = yield
      [result, deprecations]
    ensure
      context.deprecation_behavior = old_behavior
    end

    def deprecated_method_warning(context, method_name, options = nil)

      options ||= {}

      if options.is_a? String  or options.is_a? Symbol
        message = options
        options = {}
      end

      warning = "#{method_name} is deprecated and will be removed from #{options[:deprecation_horizon] || (context.deprecation_horizon if context.respond_to? :deprecation_horizon) || "a future release"}"
      case message
        when Symbol then "#{warning} (use #{message} instead)"
        when String then "#{warning} (#{message})"
        else warning
      end
    end

    private
      def deprecation_message(callstack, message = nil)
        message ||= "You are using deprecated behavior which will be removed from the next major or minor release."
        message += '.' unless message =~ /\.$/
        "DEPRECATION WARNING: #{message} #{deprecation_caller_message(callstack)}"
      end

      def deprecation_caller_message(callstack)
        if Deprecation.show_full_callstack
          return "(Callstack: #{callstack.join "\n\t"})"
        end
        file, line, method = extract_callstack(callstack)
        if file
          if line && method
            "(called from #{method} at #{file}:#{line})"
          else
            "(called from #{file}:#{line})"
          end
        end
      end

      def extract_callstack(callstack)
        offending_line = sanitized_callstack(callstack).first || callstack.first
        if offending_line
          if md = offending_line.match(/^(.+?):(\d+)(?::in `(.*?)')?/)
            md.captures
          else
            offending_line
          end
        end
      end

      def sanitized_callstack(callstack)
        callstack.reject { |line| line.start_with? deprecation_gem_root}.select { |line| (line =~ IGNORE_REGEX).nil? }
      end

      def deprecation_gem_root
        File.expand_path("../..", __FILE__) + "/"
      end
  end
end
