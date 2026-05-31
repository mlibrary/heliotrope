.. title:: Keycard, authentication for Ruby applications

Keycard Documentation
=====================

Keycard is both a Ruby library and an abstract model for authentication and
directory information for users of an application.

Keycard is primarily concerned with establishing identity and supplemental
attributes of users. It provides a data model for user information and
conveniences for building applications that will be deployed with reverse
proxies and single sign-on systems. It is well-suited to enterprise deployments
where there are external login and directory systems.

Authorization needs are not covered by Keycard at all. See Checkpoint_ for a
library that can store grants based on the Keycard attributes and enforce
policies against them.

Table of Contents
-----------------

.. toctree::
    :maxdepth: 2

    authentication.rst
    runtime_context.rst

.. _Checkpoint: https://github.com/mlibrary/checkpoint


Naming
------
Keycard takes its name from physical keycards, where a person presents a card
to a reader. The card may hold any number of attributes, including personal
identification, staff classification, or clearance levels. The reader (or
attached system) is left to make any authorization decisions or present the
information to a person to do so.
