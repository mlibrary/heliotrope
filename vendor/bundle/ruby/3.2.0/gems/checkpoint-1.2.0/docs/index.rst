.. title:: Checkpoint, policy-based authorization in Ruby

Checkpoint Documentation
========================

Checkpoint is both a Ruby library and an abstract model for authorizing user
activity within an application.

It takes its name from the concept of a physical security checkpoint, where
someone (or some device) verifies identity and credentials before granting
access to some space or resource. This documentation covers a range of topics
related to authentication and authorization, primarily focused on how to
implement secure, understandable, and maintainable business rules in web
applications built in Ruby. It comes out of the University of Michigan Library,
where enterprise, legacy, and new systems must all interoperate.

Checkpoint emphasizes the use of policies and object-oriented design, giving
examples from very simple rules through complex group- and role-based scenarios.

Checkpoint does not handle authentication at all. See Keycard_ for a library
that does so and provides identity attributes that can be used as the basis for
grants and policies.


Table of Contents
-----------------

.. toctree::
    :maxdepth: 2

    policies

.. _Keycard: https://github.com/mlibrary/keycard
