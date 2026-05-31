module Hydra::PCDM
  ##
  # Checks whether or not one object is an ancestor of another.
  module AncestorChecker
    # @param options [Hash]
    # @option record [#pcdm_behavior?]
    # @option potential_ancestor [#pcdm_behavior?]
    # @return Boolean
    def self.former_is_ancestor_of_latter?(potential_ancestor, record)
      return true if record == potential_ancestor
      return false unless potential_ancestor.respond_to?(:members)
      return true if Array.wrap(potential_ancestor.members).detect { |member| former_is_ancestor_of_latter?(member, record) }
      false
    end
    class << self
      alias call former_is_ancestor_of_latter?
    end
  end
end
