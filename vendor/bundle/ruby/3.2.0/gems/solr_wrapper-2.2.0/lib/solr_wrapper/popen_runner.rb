module SolrWrapper
  # Runs a command using popen (typically for MRI)
  class PopenRunner < Runner
    def run(stringio)
      exit_status = nil
      IO.popen(config.env, argument_list + [err: [:child, :out]]) do |io|
        if config.verbose? && !silence_output?
          IO.copy_stream(io, $stderr)
        else
          IO.copy_stream(io, stringio)
        end

        _, exit_status = Process.wait2(io.pid)
      end
      stringio.rewind
      exit_status
    end
  end
end
