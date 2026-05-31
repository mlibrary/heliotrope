# frozen_string_literal: true
require "hydra/file_characterization/version"
require "hydra/file_characterization/exceptions"
require "hydra/file_characterization/to_temp_file"
require "hydra/file_characterization/characterizer"
require "hydra/file_characterization/characterizers"
require "active_support/configurable"

module Hydra
  module_function

  # A convenience method
  def characterize(*args, &block)
    FileCharacterization.characterize(*args, &block)
  end

  module FileCharacterization
    class << self
      attr_accessor :configuration
    end

    #
    # Run all of the specified tools against the given content and filename.
    #
    # @example
    #   xml_string = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :fits)
    #
    # @example
    #   xml_string = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :fits) do |config|
    #     config[:fits] = './really/custom/path/to/fits'
    #   end
    #
    # @example
    #   xml_string = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :fits) do |config|
    #     config[:fits] = lambda {|filename| … }
    #   end
    #
    # @example
    #   fits_xml, ffprobe_xml = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :fits, :ffprobe)
    #
    # @example With an open file
    #   fits_xml, ffprobe_xml = Hydra::FileCharacterization.characterize(File.open('foo.mkv'), :fits, :ffprobe)
    #
    # @example With an open file and a filename
    #   fits_xml, ffprobe_xml = Hydra::FileCharacterization.characterize(File.open('foo.mkv'), 'my_movie.mkv', :fits, :ffprobe)
    #
    # @param [String] content - The contents of the original file
    # @param [String] filename - The original file's filename; Some
    #   characterization tools take hints from the file names
    # @param [Hash/Array] tool_names - A list of tool names available on the system
    #   if you provide a Hash
    #
    # @return [String, Array<String>] -
    #    String - When a single tool_name is given, returns the raw XML as a
    #      string
    #    Array<String> - When multiple tool_names are given, returns an equal
    #      length Array of XML strings
    #
    # @yieldparam [Hash] For any of the specified tool_names, if you add a
    #    key to the yieldparam with a value, that value will be used as the path
    #
    # @see Hydra::FileCharacterization.configure
    def self.characterize(*args)
      content, filename, tool_names = extract_arguments(args)
      tool_names = Array(tool_names).flatten.compact
      custom_paths = {}
      yield(custom_paths) if block_given?

      tool_outputs = run_characterizers(content, filename, tool_names, custom_paths)
      tool_names.size == 1 ? tool_outputs.first : tool_outputs
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    # Break up a list of arguments into two possible lists:
    #   option1:  [String] content, [String] filename, [Array] tool_names
    #   option2:  [File] content, [Array] tool_names
    # In the case of option2, derive the filename from the file's path
    # @return [String, File], [String], [Array]
    def self.extract_arguments(args)
      content = args.shift
      filename = if content.is_a?(File) && !args[0].is_a?(String)
                   File.basename(content.path)
                 else
                   args.shift
      end
      tool_names = args
      [content, filename, tool_names]
    end

    # @param [File, String] content Either an open file or a string. If a string is passed
    #                               a temp file will be created
    # @param [String] filename Used in creating a temp file name
    # @param [Array<Symbol>] tool_names A list of symbols referencing the characerization tools to run
    # @param [Hash] custom_paths The paths to the executables of the tool.
    def self.run_characterizers(content, filename, tool_names, custom_paths)
      if content.is_a? File
        run_characterizers_on_file(content, tool_names, custom_paths)
      else
        FileCharacterization::ToTempFile.open(filename, content) do |f|
          run_characterizers_on_file(f, tool_names, custom_paths)
        end
      end
    end

    def self.run_characterizers_on_file(f, tool_names, custom_paths)
      tool_names.map do |tool_name|
        FileCharacterization.characterize_with(tool_name, f.path, custom_paths[tool_name])
      end
    end

    class Configuration
      def tool_path(tool_name, tool_path)
        Hydra::FileCharacterization.characterizer(tool_name).tool_path = tool_path
      end
    end
  end
end
