# frozen_string_literal: true
module DropboxApi::Metadata
  class MemberActionList < Array
    # Builds a list of actions for a shared folder.
    #
    # @example
    #   DropboxApi::Metadata::MemberActionList.new([:leave_a_copy, :make_editor])
    #   # => [:leave_a_copy, :make_editor]
    # @see Metadata::MemberAction
    def initialize(list)
      super(list.map { |a| DropboxApi::Metadata::MemberAction.new a })
    end
  end
end
