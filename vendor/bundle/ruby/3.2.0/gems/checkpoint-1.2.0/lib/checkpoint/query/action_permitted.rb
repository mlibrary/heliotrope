# frozen_string_literal: true

module Checkpoint
  module Query
    # ActionPermitted is a predicate query that captures the user, action,
    # and target, and checks if the authority permits the action. It is likely
    # to be the most commonly issued query in any given application.
    class ActionPermitted
      attr_reader :user, :action, :target

      # @param user [<application actor>] the acting user/account
      # @param action [String|Symbol] the action to be taken; this will be
      #   forced to a symbol
      # @param target [<application entity>] the object or application resource
      #   to be acted upon; defaults to {Checkpoint::Resource.all} to ease
      #   checking for zone-/system-wide permission.
      # @param authority [Checkpoint::Authority] the authority to ask about
      #   this permission
      def initialize(
        user,
        action,
        target = Checkpoint::Resource.all,
        authority: Authority::RejectAll.new
      )
        @user = user
        @action = action.to_sym
        @target = target
        @authority = authority
      end

      def true?
        authority.permits?(user, action, target)
      end

      private

      attr_reader :authority
    end
  end
end
