LDP Implementation Overview
============================

4.2 Resource
------------

### 4.2.1 General

 - __4.2.1.1__: HTTP 1.1 is supported through Rack. Implementers can use
 Rackup, Sinatra, Rails, and other Rack-driven frameworks to fully support
 HTTP 1.1 in their servers.
 - __4.2.1.2__: Both LDP-RSs and LDP-NRs are supported. LDP-RS is the default
 interaction model; clients must request an LDP-NR specificially at time of
 creation.
 - __4.2.1.3__: Etags are generated for all LDPRs and returned for all requests
 to the resource.
 - __4.2.1.4__: Link headers for the __returned__ resource are added by
 `Rack::LDP::Headers` middleware. The requirement to return Link headers for
 the requested resource is ignored in the case of successful POST requests;
 instead, the headers for the created resource are given.
 - __4.2.1.5__: Relative URI resolution in RDF graphs is handled with
 `RDF::Reader#base_uri`. This is tested for Turtle input.
 - __4.2.1.6__: Constraints are published in the {CONSTRAINED_BY.md} file in
 this repository. Additional, implementation specific constraints should be
 published by the server implementer and added to the headers for the server.

### 4.2.2 HTTP GET

 - __4.2.2.1__: LDPRs support GET.
 - __4.2.2.2__: The "Allow" headers specified for OPTIONS are returned with
 all requests for a given resource; this is handeled by the `Rack::LDP::Headers`
 middleware.

### 4.2.3 HTTP POST

 - POST is supported for LDP Containers, constranits are published in
 {CONSTRAINED_BY.md}. See: __4.2.1.6__ for details.

### 4.2.4 HTTP PUT

 - __4.2.4.1__: RDFSources completely replace the content of existing graphs with
 the graph in the PUT request body. Any properties to be handled by the server
 with update restrictions are left to implementers to enforce. 
 - __4.2.4.2__: See: __4.2.4.1__ 
 - __4.2.4.3__: Server allows client to modify all content except that
 explicitly excluded by LDP (i.e. server-managed-triples), which are handled
 as described under relevant sections.
 - __4.2.4.4__: Server persists all content PUT to LDP-RS's, per __4.2.4.1__.
 - __4.2.4.5__: [IGNORED SHOULD] Etags are checked as specified IF an
 `If-Match` header is present. `If-Match` headers are NOT required, and requests
 without them will operate as though the correct Etag has been given. We
 consider "_clients SHOULD use the HTTP If-Match header_".
 - __4.2.4.6__: Sending a PUT request to a non-existant Resource creates a
 Resource at that URI with the selected interaction model (defaulting to
 ldp:RDFSource). The created Resource will not be in any container.

### 4.2.5 HTTP DELETE

 - DELETE is supported

### 4.2.6 HTTP HEAD

 - __4.2.6.1__: HEAD is supported. See: __4.2.2.2__ for details on HTTP headers.

### 4.2.7 HTTP PATCH

 - PATCH support is implemented with the LDPatch format and with SPARQL Update.

### 4.2.8 HTTP OPTIONS

 - __4.2.8.1__: OPTIONS is supported for all resources. 
 - __4.2.8.2__: See: __4.2.2.2__ for details on HTTP headers.

4.3 LDP RDFSource
------------------

### 4.3.1 General

 - __4.3.1.1__: Each LDP-RS is an LDPR as described in this reports description
 of __4.2__.
 - __4.3.1.2__: [IGNORING SHOULD] Enforcement of the presence rdf:type is left
 to the client and/or server implementer. This software does not add or manage
 rdf:type in its representations.
 - __4.3.1.3__: See: __4.3.1.2__.
 - __4.3.1.4__: See: __4.2.2.1__. Content negotiation for returned RDF
 representations is handled by `Rack::LDP::ContentNegotiation`, which inherits
 `Rack::LinkedData::ContentNegotiation`.
 - __4.3.1.5-6__: Vocabulary use is left to the client.
 - __4.3.1.7-9__: These are constraints on the client, not addressed by this
 software.
 - __4.3.1.10__: No specialized rules about update or graph contents are
 enforced by this software. It requires no inferencing.
 - __4.3.1.11-13__: These are constraints on the client, not addressed by this
 software.

### 4.3.2 HTTP GET

 - __4.3.2.1__: [UNKNOWN] The default return type is `text/turtle`. No testing
 has been performed for the tie breaks prescribed in this section. Content
 negotiation is handled by `Rack::LDP::ContentNegotiation`.
 - __4.3.2.2__: The default return type is `text/turtle`.
 - __4.3.2.3__: [UNKNOWN] Content negotiation for explicit `application/ld+json`
 requests is functional. No testing has been performed for the tie breaks prescribed
 in this section.

4.4 Non-RDFSource
------------------

### 4.4.1 General

 - __4.4.1.1__: Each LDP-NR is an LDPR as described in this reports description
 of __4.2__. LDP-NRs are persisted through a `StorageAdapter` allowing easily
 swappable approaches to persistence.
 - __4.4.1.2__: LDP-NRs include the specified Link header on all requests.

5.2 Container
--------------

### 5.2.1 General

 - __5.2.1.1__: Each LDPC is an LDP-RS as described in this report's description
 of __4.2__.
 - __5.2.1.2-3__: rdf:type is left to the client and/or implementer.
 - __5.2.1.4__: Link headers for type are added for all Resources; See:
 __4.2.1.4__.
 - __5.2.1.5__: [IGNORING SHOULD] Client hints are unimplemented. We are
 considering including them in future development. [TODO]

### 5.2.2 HTTP GET

 - __5.2.2.1__: See: __4.3.2.1__.

### 5.2.3 HTTP POST
 - __5.2.3.1__: Server responds 201 unless an error is thrown while completing
 the POST.
 - __5.2.3.2__: Server adds a containment triple with predicate `ldp:contains`
 when POST is successful.
 - __5.2.3.3__: POSTs of LDP-NRs are accepted if the client specifies the LDP-NR
 interaction model. Content types for LDP-NRs must be sent in a request header.
 - __5.2.3.4__: Honors LDP interaction models in HTTP Link headers. Requests
 without an interaction model specified are treated as requests to create an
 LDP-RS.
   - Interaction models are honored for all of LDP-RS, LDP-NR, LDPC, as well as
   Basic, Direct, and Indirect container types.
   - Requests for LDPRs are treated as LDP-RS. We read the specification as
   vague with respect to the clause about requested LDPR interaction model.
   This behavior represents our interpretation.
 - __5.2.3.5__: POST requests to create an LDP-RS accept all content types
 supported with an `RDF::Reader` in the `linkeddata` gem (including
 'text/turtle').
 - __5.2.3.6__: The server relies solely on the `Content-Type` headers to
 understand the format of posted graphs. Requests without a `Content-Type` (or
 body) will fail.
 - __5.2.3.7__: Relative URI resolution in RDF graphs is handled with
 `RDF::Reader#base_uri`. This is tested for Turtle input.
 - __5.2.3.8__: Created resources are assigned UUID's with the container as
 the base URI when no Slug header is present.
 - __5.2.3.9__: No constraints on graph contents are imposed.
 - __5.2.3.10__: Slug headers are treated as non-negotiable requests to create
 a resource at [container-uri]/[Slug]. If a resource exists at that address the
 request will fail.
 - __5.2.3.11__: Deleted resources are tombstoned and their URI's are protected
 from future use.
 - __5.2.3.12__: When an LDP-NR is created, an LDP-RS is created at
 `[ldp-nr-uri]/.well-known/desc`. The `describedBy` Link header is added.
 - __5.2.3.13__: Accept-Post headers are added to all responses from resources
 that accept post requests. Content types are added dynamically when new
 RDF::Readers are loaded.
 - __5.2.3.14__: See: __5.2.3.5__.

### 5.2.4 HTTP PUT

- __5.2.4.1__: Responds with 409 when attempting to write containment triples
that do not already exist.
- __5.2.4.2__: See: __5.2.3.11__.

 
### 5.2.5 HTTP DELETE

 - __5.2.5.1__: Containment triples are removed as required when a resource is destroyed.
 - __5.2.5.2__: See: __5.2.8.1__.

### 5.2.6 HTTP HEAD

 - See: __4.2.6__

### 5.2.7 HTTP PATCH

 - See: __4.2.7__

### 5.2.8 HTTP OPTIONS

 - __5.2.8.1__: The related LDP-RSs are created and the required Link headers
 are included on all requests to LDP-NRs.

5.3 Basic Container
--------------------

### 5.3.1 General

 - __5.3.1.1__: Basic Containers are treated as an alias for Container.

5.4 Direct Container
--------------------

### 5.4.1 General

- __5.4.1.1__: DirectContainers inherit all BasicContainer behavior
- __5.4.1.2__: `ldp:member` is used as the default predicate in cases where the
client provides none.
- __5.4.1.3__: We enforce the inclusion of _exactly one_
`ldp:membershipResource` by:
  - adding the LDPDC as the `ldp:membershipResource` if the client does not
  provide one.
  - rejecting POST requests with `NotAcceptable` if more than one is present
We allow clients to change triples including `ldp:membershipResource` at their
own risk.
- __5.4.1.4__: The behaivor described in __5.4.1.3__ applies to statements
with either of `ldp:hasMemberRelation` and `ldp:isMemberOfRelation`.
- __5.4.1.5__: We implement the `ldp:MemberSubject` behavior as described and
ignore `ldp:insertedContentRelation` on DirectContainers.

### 5.4.2 POST

- __5.4.2.1__: Triples are created as described when POSTing to a container. We
allow clients to delete and replace triples at their own risk, per the MAY in
this section.
  - Membership triples are added to the containers graph for both the
  `ldp:hasMemberRelation` and `isMemberOfRelation` cases.
  - If the Membership Resource is an LDP-NR, membership triples are added to
  the server-created LDP-RS (`describedby`, resource).
  - POST requests are rejected if the Membership Resource does not exist.


### 5.4.2 DELETE

- __5.4.3.1__: Triples are deleted as described in this section.


5.5 Indirect Container
-----------------------

### 5.5.1 General

- __5.5.1.1__: Indirect Containers are implemented as a subclass of Direct
Containers, inheriting all of their behavior.
- __5.5.1.2__: We enforce the inclusion of _exactly one_
`ldp:insertedContentRelation` by:
  - adding `ldp:MemberSubject` if the client does not provide one.
  - rejecting POST requests with `NotAcceptable` if more than one is present.
We allow clients to change triples including `ldp:insertedContentRelation` at
their own risk.

POST requests for LDP-NRs and LDP-RSs missing an expected inserted content
relation, or with multiple inserted content relations, are also rejected with
`NotAcceptable`.

### 5.5.2 HTTP POST

- __5.5.2.1__: `ldp:contains` triples are added in the same way as with Basic
and Direct Containers.

Handling of Non-Normative Notes
================================

 - __6.2.2__ We supply swappable backends via the `RDF::Repository` abstraction.
 Clients may edit the resources available to LDP freely through the interfaces
 provided by `RDF::Repository` or by other means. Resources are marked as LDPRs
 by the presence of a specific named graph structure, which should be maintained
 for resources indended to be created or accessed over this server.
 - __6.2.3__ After delete, we supply `410 GONE` responses. Resourced deleted are
 treated as permanently deleted. Clients may recover them manually.
 - __6.2.5__ PATCH support is implemented with the LDPatch format and with SPARQL
 Update.
 - __6.2.6__ We do not infer content types (or LDP interaction models) from
 resource contents, instead relying exclusively on the headers defined and used
 by LDP.
 - __6.3.1__ We allow clients complete control over graph contents, except
 where LDP _requires_ otherwise.


Test Suite
==========
