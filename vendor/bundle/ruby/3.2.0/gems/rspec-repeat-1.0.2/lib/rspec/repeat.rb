require 'rspec/repeat/version'

module RSpec
  # Allows you to repeat RSpec examples.
  module Repeat
    # Retries an example.
    #
    #     include Rspec::Repeat
    #
    #     around do |example|
    #       repeat example, 3
    #     end
    #
    # Available options:
    #
    # - `wait` - seconds to wait between each retry
    # - `verbose` - print messages if true
    # - `exceptions` - if given, only retry exceptions from this list
    # - `clear_let` - when false, don't clear `let`'s
    #
    def repeat(ex, count, options = {})
      Repeater.new(count, options).run(ex, self)
    end

    # Much of this code is borrowed from:
    # https://github.com/NoRedInk/rspec-retry/blob/master/lib/rspec/retry.rb
    class Repeater
      attr_accessor :count, :wait, :exceptions, :verbose, :clear_let

      def initialize(count, options = {})
        options.each do |key, val|
          send :"#{key}=", val
        end

        self.count = count
        self.count = count.times if count.is_a?(Numeric)
        self.verbose = ENV['RSPEC_RETRY_VERBOSE'] if verbose.nil?
        self.clear_let = true if clear_let.nil?
      end

      def run(ex, ctx)
        example = current_example(ctx)

        count.each do |i|
          example.instance_variable_set :@exception, nil
          ex.run
          break if example.exception.nil?
          break if !matches_exceptions?(exceptions, example.exception)
          print_failure(i, example) if verbose
          clear_memoize(ctx) if clear_let
          sleep wait if wait.to_i > 0
        end
      end

      # Returns the current example being ran by RSpec
      def current_example(ctx)
        if RSpec.respond_to?(:current_example)
          RSpec.current_example
        else
          ctx.example
        end
      end

      # Clears memoized stuff out of an ExampleGroup to clear out the `let`s
      def clear_memoize(ctx)
        if ctx.respond_to?(:__init_memoized, true)
          ctx.send :__init_memoized
        else
          ctx.instance_variable_set :@__memoized, nil
        end
      end

      # Checks if `exception` is in `exceptions`
      def matches_exceptions?(exceptions, exception)
        return true unless exceptions
        exceptions.any? do |exception_klass|
          exception.is_a?(exception_klass)
        end
      end

      def print_failure(i, example)
        msg =
          "RSpec::Repeat: #{nth(i + 1)} try error in #{example.location}:\n" \
          "  #{example.exception}\n"
        RSpec.configuration.reporter.message(msg)
      end

      # borrowed from ActiveSupport::Inflector
      def nth(number)
        if (11..13).include?(number.to_i % 100)
          "#{number}th"
        else
          case number.to_i % 10
          when 1 then "#{number}st"
          when 2 then "#{number}nd"
          when 3 then "#{number}rd"
          else "#{number}th"
          end
        end
      end
    end
  end
end
