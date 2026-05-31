# frozen_string_literal: true

require "checkpoint/query/role_granted"
require "checkpoint/query/action_permitted"

module Checkpoint
  # The Query module is a container for the various types of checks or
  # inquiries that an application might want to make.
  #
  # These classes provide a more expressive and object-oriented pattern than
  # scattering the primitives and throughout the framework (and, more
  # importantly, application) code base. They improve consistency and
  # ergonomics in a similar way as named queries or scopes on a model class.
  # That is, it's possible to query the authority directly (or model, by
  # comparison) with primitives, but these classes will capture the semantics
  # of a particular check, taking the conceptually pertinent parameters, and
  # applying any defaults or conversion to authoriziation primitives needed,
  # particularly around credential types.
  #
  # Despite modeling the semantics of a query in a convenient way, these
  # objects do not assume a singleton authority. To make their usage truly
  # convenient, they should be created from a factory method that binds them to
  # an already-configured {Checkpoint::Authority}.
  #
  # NOTE: @botimer 2018-02-25: I suspect that we will build a convenience class
  # that binds an authority, and has a factory method per query. This might end
  # up being the main interface to Checkpoint; a wide-but-shallow adapter
  # object that can be set up at initialization and made available to
  # application policies (rather than using the authority directly). I also
  # suspect that a shorthand adapter will appear for convenient aliasing in
  # context. For example, a `can?` method on a base application policy that
  # requires only an action parameter, binding its user and resource by
  # default, would be a familiar and ergonomic way to call `action_permitted`.
  # This would create and evaluate a new ActionPermitted instance bound to the
  # parameters and the configured authority. A pattern like this would achieve
  # the concurrent goals of maintaining the framework design and call-site
  # simplicity, without relying on mixins -- the delegation to Checkpoint would
  # be made explicit with some short boilerplate in application code that can
  # be found and examined without digging into gems.
  module Query
  end
end
