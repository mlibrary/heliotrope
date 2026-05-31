# frozen_string_literal: true
module DropboxApi::Results
  class BasicAccountBatch < Array
    def initialize(accounts)
      super(accounts.map { |a| DropboxApi::Metadata::BasicAccount.new a })
    end
  end
end
