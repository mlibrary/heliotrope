# frozen_string_literal: true

module Checkpoint
  module Query
    # RoleGranted is a predicate query that captures the user, role, and
    # target, and checks if the authority recognizes the user as having the
    # role.
    #
    # TODO: Extract-To-Manual
    # There are two primary approaches to handling which actions are permitted
    # for which roles:
    #
    # 1. Encoding the details directly in policy objects and checking for the
    #    appropriate roles within a given rule. This has the effect of placing
    #    the literal values within the body of a rule, making it quite easy
    #    to examine. Tests can validate system behavior at development time
    #    because it is static.
    #
    # 2. Implementing a {Checkpoint::Credential::Resolver} that maps backward
    #    from actions to named permissions and roles that would allow them.
    #    The policy rules would only authorize actions, leaving the mapping
    #    outside to accommodate configuration or runtime modification. This has
    #    the effect of being more flexible, while making the specifics of a
    #    rule more difficult to examine. Tests can only validate system
    #    behavior for a particular configuration -- whether an instance of the
    #    application is configured in a correct or expected way is not testable
    #    at development time.
    class RoleGranted
      attr_reader :user, :role, :target

      # @param user [<application actor>] the acting user/account
      # @param role [String|Symbol] the role to be checked; this will be
      #   forced to a symbol
      # @param target [<application entity>] the object or application resource
      #   for which the user may have a role; defaults to {Checkpoint::Resource.all}
      #   to ease checking for zone-/system-wide roles.
      # @param authority [Checkpoint::Authority] the authority to ask about
      #   this role-grant
      def initialize(user, role, target = Resource.all, authority: Authority::RejectAll.new)
        @user = user
        @role = role.to_sym
        @target = target
        @authority = authority
      end

      def true?
        authority.permits?(user, Credential::Role.new(role), target)
      end

      private

      attr_reader :authority
    end
  end
end
