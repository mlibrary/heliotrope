module SolrWrapper
  # An abstract class for running commands in the shell
  class Runner
    def initialize(cmd, options, config)
      @cmd = cmd
      @silence_output = !options.delete(:output)
      @options = options
      @config = config
    end

    attr_reader :cmd, :options, :config

    def silence_output?
      @silence_output
    end

    private

    def argument_list
      [config.solr_binary, cmd] + config.solr_options.merge(options).map do |k, v|
        case v
        when true
          "-#{k}"
        when false, nil
          nil
        else
          ["-#{k}", v.to_s]
        end
      end.flatten.compact
    end
  end
end
