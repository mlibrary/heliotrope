# frozen_string_literal: true
module DropboxApi
  class ResultBuilder
    def initialize(response_data)
      @response_data = response_data
    end

    def error_summary
      @response_data['error_summary'] if @response_data.is_a? Hash
    end

    def error
      @response_data['error']
    end

    def has_error?
      !error_summary.nil?
    end

    def success?
      !has_error?
    end

    def build(result_class)
      result_class.new(@response_data)
    end

    def build_error(error_type)
      error_type.build(error_summary, error)
    end
  end
end
