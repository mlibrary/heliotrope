# frozen_string_literal: true

module DropboxApi::Metadata
  class FileCategoriesList < Array
    def initialize(list)
      super(list.map { |c| DropboxApi::Metadata::FileCategory.new c })
    end
  end
end
