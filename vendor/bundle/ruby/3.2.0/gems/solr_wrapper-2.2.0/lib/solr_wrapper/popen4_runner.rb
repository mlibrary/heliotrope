module SolrWrapper
  # Runs a command using popen4 (typically for JRuby)
  class Popen4Runner < Runner
    def run(stringio)
      pid, input, output, error = IO.popen4(command)
      if config.verbose? && !silence_output?
        IO.copy_stream(output, $stderr)
        IO.copy_stream(error, $stderr)
      else
        IO.copy_stream(output, stringio)
        IO.copy_stream(error, stringio)
      end

      input.close
      output.close
      error.close
      exit_status = Process.waitpid2(pid).last
      stringio.rewind
      exit_status
    end

    private

    def command
      env_str + ' ' + argument_list.join(' ')
    end

    def env_str
      config.env.map { |k, v| "#{Shellwords.escape(k)}=#{Shellwords.escape(v)}" }.join(' ')
    end
  end
end
