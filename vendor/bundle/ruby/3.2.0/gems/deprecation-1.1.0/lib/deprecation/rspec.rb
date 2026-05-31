module Deprecation
  class RSpec
    if defined? ::RSpec and $0 =~ Regexp.union(/rake/, /rspec/)
      require 'rspec/core'

      Deprecation.default_deprecation_behavior = :stderr_report

      ::RSpec.configure do |config|
        config.after(:suite) do
          Deprecation::RSpec.report $stderr
        end
      end
    end

    def self.report io
      return if Deprecation.deprecations.empty?
      io.puts "\n\n==== DEPRECATION WARNINGS ===="
      Deprecation.deprecations.each do |hash, obj|
        io.puts(obj[:message] + " (#{obj[:count]} times); e.g.: ")
        io.puts("    " + obj[:callstack][0..4].join("\n    ") + "\n\n")
      end

      io.puts <<-EOF
      If you need more of the backtrace for any of these deprecations to identify
      where to make the necessary changes, you can configure 
      `Deprecation.default_deprecation_behavior = :raise`, and it will turn the deprecation
      warnings into errors, giving you the full backtrace.
      EOF
      io.puts "\n\n========\n\n"
    end
  end
end