# frozen_string_literal: true

require 'csv'

module CounterSummaryService
  class CsvProcessor
    attr_reader :errors

    def initialize
      @errors = []
    end

    def process_file(file_path)
      rows = []
      CSV.foreach(file_path, headers: true) do |row|
        rows << row.to_h
      end
      rows
    rescue CSV::MalformedCSVError => e
      @errors << "CSV parsing error: #{e.message}"
      []
    rescue Errno::ENOENT => e
      @errors << "File not found: #{e.message}"
      []
    end
  end
end
