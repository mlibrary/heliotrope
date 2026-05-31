# frozen_string_literal: true
require 'hydra/file_characterization/exceptions'
require 'open3'
require 'active_support/core_ext/class/attribute'

module Hydra::FileCharacterization
  class Characterizer
    include Open3

    class_attribute :tool_path

    attr_reader :filename
    def initialize(filename, tool_path = nil)
      @filename = filename
      @tool_path = tool_path
    end

    def call
      raise Hydra::FileCharacterization::FileNotFoundError, "File: #{filename} does not exist." unless File.exist?(filename)

      post_process(output)
    end

    def tool_path
      @tool_path || self.class.tool_path || convention_based_tool_name
    end

    def logger
      @logger ||= activefedora_logger || Logger.new(STDERR)
    end

    protected

    # Override this method if you want your processor to mutate the
    # raw output
    def post_process(raw_output)
      raw_output
    end

    def convention_based_tool_name
      self.class.name.split("::").last.downcase
    end

    def internal_call
      stdin, stdout, stderr, wait_thr = popen3(command)
      begin
        out = stdout.read
        err = stderr.read
        exit_status = wait_thr.value
        raise "Unable to execute command \"#{command}\"\n#{err}" unless exit_status.success?
        out
      ensure
        stdin.close
        stdout.close
        stderr.close
      end
    end

    def command
      raise NotImplementedError, "Method #command should be overriden in child classes"
    end

    private

    def output
      if tool_path.respond_to?(:call)
        tool_path.call(filename)
      else
        internal_call
      end
    end

    def activefedora_logger
      ActiveFedora::Base.logger if defined? ActiveFedora
    end
  end
end
