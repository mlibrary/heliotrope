Policies
========

A single, consistent model for authorizing user actions is helpful in
developing secure, correct applications. One basic approach to this is to use
what are called **Policy Objects** (or simply **policies**). This is somewhat
different than declarative or hybrid systems like CanCan, for example.

With CanCan, there is a convenient method for declaring that a user "can do"
something, building up a map of the users' permitted actions on each request.
This breaks down somewhat when dynamic roles and object state must be
considered. The typical solution is to provide a block that serves as a boolean
predicate for a given operation. This leads to a hybrid of statements and
predicates, with no clear pattern for what should be placed where.

The policy approach is slightly different in that it assumes there will be an
object that can answer "yes" or "no" to the question of whether a given user
can take a given action. This **rule** may need detailed contextual information
like two objects that the user would like to associate, but the "answer" is not
precomputed. This consistency is useful because object-oriented principles can
be applied readily, giving handy tools for organizing and composing the domain
rules.

There is some variation in how policies are constructed, particularly in
whether they are resource- or operation-oriented. Resource-oriented policies
tend to have one object covering multiple REST/CRUD operations with associative
operations being covered on a separate policy for logical resources (e.g., a
"membership"). Operation-oriented policies tend to cover one domain action per
object, though this is a flexible design decision where a policy may cover a
number of related actions.

For the sake of the following discussion, a rule should be considered as
applying for a specific action, without regard for whether it is the only rule
of a policy or one of multiple rules on a broader policy.


Rules vs. Facts
---------------

One important distinction is that of **Rules** versus **Facts**. A given rule
will generally be static but may consider dynamic facts. For example, a rule
may state that a user may only delete documents they own. The rule considers
dynamic facts of who is acting and the owner of the object acted upon; it has a
context of two parameters.

Types of Rules
--------------

Rules sit on a continuum of how dynamic their context is; that is, how much
external information is needed to make the decision, and where that information
comes from. The extent to which a rule uses dynamic information can inform how
it is constructed.

In general, rules that consider few and simple facts should be implemented as
directly as possible, in the source code, and without calling out to additional
collaborators. This facilitates understanding and testing by limiting the scope
of what could result in different answers.

Rules that consider more facts and those that are complicated to derive deserve
some indirection as to avoid coupling to complexity that does not belong to the
rule itself, as well as duplication of conceptual elements (such as how role
hierarchy should imply additional permissions).

Some patterns can be applied to the rule code and fact data to avoid repeating
design activity and incidental variation that is unhelpful across multiple
applications in an organization. These examples are not necessarily exhaustive,
but aim to provide a representative range with extremes identified. 

Totally Static
~~~~~~~~~~~~~~

The rule is encoded in the application and will yield the same answer until the
source code is changed. This may be used a placeholder for a permission check
for a feature not yet enabled or as a deprecation tool to disable an action
while source-level invocations are removed. This type of rule is uncommon, only
really useful in transition to richer implementation or removal.

Configuration-Only
~~~~~~~~~~~~~~~~~~

The rule considers only a system configuration value and no other contextual
information. This is functionally equivalent but semantically preferable to a
"feature flag" because the conceptual focus remains on whether the user is
permitted to take some action. The policy becomes a simple indirection point,
behind which the implementation of making the decision (flag, role, etc.) can
vary without changing the calling code.

An example of a user-oriented (but not user-specific) setting might be "delete
items", set in a system configuration file. Whether the action is permitted
should be conditioned by a rule that consults the setting. This type of rule
often evolves to account for concerns like whether the user has administrator
access or owns an object. Especially if the permission would be checked in
multiple places, a rule is preferable to maintain consistency of authorization
and discourage "authorization in disguise", such as scattered checks against a
flag or whether the user is an administrator.

Note that feature flags are appropriate to consult directly when system
behavior should be conditional, but is unlikely to vary based on the acting
user. An example of this might be whether the implementors have decided to
enable "social widgets" or PDF export across an entire web application. This is
not a matter of authorization, so it should not be implemented as a rule.

User and Resource
~~~~~~~~~~~~~~~~~

The rule considers the acting user in combination with a target resource or
multiple resources. This is a very common rule type for which the policy
approach shines in comparison to the declarative or hybrid approaches. Rules of
this type will often check that the user owns the resource or a container, a
user attribute like "is administrator", object state such as whether a document
is in draft mode, or conditions such as publication or retraction dates versus
the current time.

This type of rule is usually quite concise in its expression in source code,
which helps clarify behavior so that it can be implemented, verified,
communicated, and maintained with confidence.

User, Resource, and Context
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The rule considers the user, the target resource, and contextual information
such as region as determined by IP address, usage quotas, or configuration. A
small extension to *User and Resource* rule type, the additional context is not
usually supplied by the calling code (as are the user and resource), but
retrieved from the environment or usage session information.

System Role and Resource
~~~~~~~~~~~~~~~~~~~~~~~~

Rules of this type are similar to *User and Resource* rules, but they also
consider the user's system-wide role, typically an attribute of the user from a
fixed set of application roles. An administrator flag is commonly converted to
a named role when using this model.

For this discussion, a role implies a fixed set of permitted actions. For example, an
"editor" may be able to update items, but not delete them. This would be encoded
directly in the rule, only changing when the application changes.

Agent and Resource
~~~~~~~~~~~~~~~~~~

The rule considers the acting user and the target resource, in light of
permitted agents. An **agent** is an abstraction of a permitted user or group.
There is some semantic overlap in common usage of the terms group and role. For
this discussion, a group serves as a simple set of users, not directly implying
any permitted actions like a role would. A group could serve as a container for
resources or be permitted to take actions on a resource by a property such as
"shared with". The agent abstraction allows actions to be permitted to single
users or groups without spreading conditional handling for both cases
throughout an application.

A rule of this type will commonly check the equivalent of information like
whether the user owns the resource, if the resource is shared directly with the
user, or if any of the groups to which the user belongs matches any of the
groups that the resource is shared with.

The agent abstraction reduces this type of check to whether the agent owns the
resource or if the resource is shared with the agent. The rules can remain
simple with the consistent semantics of "user or group" externalized.

Agent, Resource, Context, Role, and Permissions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The rule considers all of the above information in addition to dynamic
permissions granted to roles. The roles may be fixed by the application or
configurable. The permissions implied by a role are not fixed and must be
resolved at runtime. The configuration of the permissions may occur as a
customization of a deployed source file, a system configuration file read at
startup, or persisted elsewhere.

Inspecting rules of this type is much more abstract and requires significantly
more knowledge of the deployment infrastructure and configuration model,
especially if the permissions are granted in a database. Tests can only verify
that the right authorization questions are asked and answered as expected for
example configurations; they are no longer effective for verifying that an
application will behave as desired in production. The implementors hold the
responsibility for ensuring that the configuration is correct.

Significant tooling is typically built to allow runtime inspection or
modification of permissions within applications with this level of flexibility.

"One Rule"
~~~~~~~~~~

In scenarios where groups, roles, permissions, and actions must be allowed to be
defined at runtime, the rules tend to become very generic while the "fact" data
becomes very detailed. Almost no literal values will be used in a rule, relying
on assembly of a set of attributes and requirements from persisted data. Taken
far enough, this approach sometimes reduces the set of business rules to "one
rule" serving as a first-order logic solver over a fully dynamic set of facts.
All parts of the application must make authorization requests in a generic
format to a single point of control.

Systems needing this level of flexibility are rare. For example, it is
sometimes seen in the ERP and CMS spaces where installers build workflows,
modules, and whole business applications in that environment at runtime -- the
developers of the base application implement a development environment as much
as a specific application. Inspection or modification of rules and facts in a
system of this complexity requires extensive operational tooling and expertise.

Enterprise Authorization
~~~~~~~~~~~~~~~~~~~~~~~~

Some enterprises externalize application rules to policy systems. The
applications formulate requests in a standardized format, being explicit about
the subject, resources, and action in terms of enterprise identifiers. These
requests are then validated against policies managed at the enterprise level.
This approach provides consistency across applications and services at an
enormous complexity and operational cost, hence it will not be under further
discussion here.

