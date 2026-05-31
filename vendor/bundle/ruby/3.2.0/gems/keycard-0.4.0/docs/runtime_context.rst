Runtime Context
===============

An application can be run in different environments and configurations for
different purposes like development, testing, staging, or public use. There are
many overlapping terms in use, so, for our purposes here, we use the term
*Runtime Context* to give labels to the scenarios where the infrastructure is
different, and in what ways.

Development Context
-------------------

This means that the application is running with direct access by the client,
generally from a workstation. There is no front-end server, so all
authentication must be managed by the application. The Rails environment is
generally set to ``development``.

A proxy managing single sign-on may be emulated either at the Rack or
application level if needed. Generally, there is some bit of UI or cookie/param
handling exposed only in development mode to influence how the requests appear
to the application, or there is a login form for local accounts.

Deployment Context
------------------

This means that the application is deployed to dedicated infrastructure. There
is a front-end server (proxy) that may or may not manage single sign-on. The
Rails environment is generally set to ``production``.

A typical configuration is to have an Apache web server proxying all traffic,
with either a module for Cosign, CAS, or Shibboleth configured. There is often
a fixed path (e.g., ``/login``) that is intercepted to require SSO
authentication. If the user is authenticated, the request is forwarded on with
headers in place. If the user cannot authenticate, the app never receives  the
login path request. For Shibboleth scenarios, there is a Service Provider that
is set up for the endpoint (application URL).

With Shibboleth, it is also possible to have the headers present on each
request when there is an active session with the Service Provider. Some special
care must be taken here that sessions are initiated and terminated properly and
when desired (usually on login and logout requests).

