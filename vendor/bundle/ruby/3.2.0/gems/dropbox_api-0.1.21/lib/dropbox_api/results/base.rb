# frozen_string_literal: true
module DropboxApi::Results
  class Base
    def initialize(result_data)
      @data = result_data
    end
  end
end
