require 'open3'
module Riiif
  # Runs shell commands under benchmark and saves the output
  class CommandRunner
    include Open3
    include ActiveSupport::Benchmarkable
    delegate :logger, to: :Rails

    # TODO: this is being loaded into memory.  We could make this a stream.
    # @return [String] all the image data
    def execute(command)
      out = nil
      benchmark("Riiif executed #{command}") do
        stdin, stdout, stderr, wait_thr = popen3(command)
        stdin.close
        stdout.binmode
        out = stdout.read
        stdout.close
        err = stderr.read
        stderr.close
        raise ConversionError, "Unable to execute command \"#{command}\"\n#{err}" unless wait_thr.value.success?
      end
      out
    end

    def self.execute(command)
      new.execute(command)
    end
  end
end
