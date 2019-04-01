# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'json'

module RestfulFedora
  class Service
    def initialize(options = {})
      @base = options[:base] || RestfulFedora.url
    end

    def contains
      response = connection.get do |request|
        request.url RestfulFedora.base_path
        request.options[:timeout] = 3600 # 1 hour
        request.options[:open_timeout] = 4800 # 1.5 hours
      end
      return [] unless response.success? && response.body.present? && response.body.first.present? && response.body.first.is_a?(Hash)
      ldp_contains = response.body.first["http://www.w3.org/ns/ldp#contains"] || []
      ldp_contains.map { |h| h["@id"] }
    end

    def node(url) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      response = connection.get do |request|
        request.url url
        request.options[:timeout] = 3600 # 1 hour
        request.options[:open_timeout] = 4800 # 1.5 hours
      end
      json_ld = {}
      json_ld["@id"] = url
      json_ld["@type"] = ["http://www.gkostin.com/ns/Faraday#Response"]
      # json_ld["http://www.gkostin.com/ns/Faraday#Response:request"] = [{ "@type" => "http://www.w3.org/2001/XMLSchema#string", "@value" => response.request }]
      # json_ld["http://www.gkostin.com/ns/Faraday#Response:response"] = [{ "@type" => "http://www.w3.org/2001/XMLSchema#string", "@value" => response.response }]
      json_ld["http://www.gkostin.com/ns/Faraday#Response:status"] = [{ "@type" => "http://www.w3.org/2001/XMLSchema#long", "@value" => response.status }]
      # json_ld["http://www.gkostin.com/ns/Faraday#Response:headers"] = [{ "@type" => "http://www.w3.org/2001/XMLSchema#string", "@value" => response.headers }]
      json_ld["http://www.gkostin.com/ns/Faraday#Response:body"] = [{ "@type" => "http://www.w3.org/2001/XMLSchema#string", "@value" => response.body }]
      case response.status
      when 400
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#BadRequest"]
      when 404
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#NotFound"]
      when 405
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#MethodNotAllowed"]
      when 406
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#NotAcceptable"]
      when 409
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#Conflict"]
      when 410
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#Gone"]
      when 412
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#PreconditionFailed"]
      when 415
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError", "http://www.w3.org/ns/ldp#UnsupportedMediaType"]
      when 500
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError"]
      when 200
        json_ld = response.body
      else
        json_ld["@type"] = ["http://www.w3.org/ns/ldp#RequestError"]
      end

      context = JSON.parse(%({
        "@context" : {
          "id" : "@id",
          "type" : "@type",

          "ldp" : "http://www.w3.org/ns/ldp#",
          "RequestError" : "ldp:RequestError",
          "Gone" : "ldp:Gone",
          "NotFound" : "ldp:NotFound",
          "Container" : "ldp:Container",
          "BasicContainer" : "ldp:BasicContainer",
          "DirectContainer" : "ldp:DirectContainer",
          "IndirectContainer" : "ldp:IndirectContainer",
          "hasMemberRelation" : { "@id" : "ldp:hasMemberRelation", "@type" : "@id" },
          "isMemberOfRelation" : { "@id" : "ldp:isMemberOfRelation", "@type" : "@id" },
          "membershipResource" : { "@id" : "ldp:membershipResource", "@type" : "@id" },
          "insertedContentRelation" : { "@id": "ldp:insertedContentRelation", "@type" : "@id" },
          "contains" : { "@id" : "ldp:contains", "@type" : "@id" },
          "member" : { "@id" : "ldp:member", "@type" : "@id" },
          "constrainedBy" : { "@id" : "ldp:constrainedBy", "@type" : "@id" },
          "Resource" : "ldp:Resource",
          "RDFSource" : "ldp:RDFSource",
          "NonRDFSource" : "ldp:NonRDFSource",
          "MemberSubject" : "ldp:MemberSubject",
          "PreferContainment" : "ldp:PreferContainment",
          "PreferMembership" : "ldp:PreferMembership",
          "PreferMinimalContainer" : "ldp:PreferMinimalContainer",
          "PageSortCriterion" : "ldp:PageSortCriterion",
          "pageSortCriteria" : { "@id" : "ldp:pageSortCriteria", "@type" : "@id", "@container" : "@list" },
          "pageSortPredicate" : { "@id" : "ldp:pageSortPredicate", "@type" : "@id" },
          "pageSortOrder" : { "@id" : "ldp:pageSortOrder", "@type" : "@id" },
          "pageSortCollation" : { "@id" : "ldp:pageSortCollation", "@type" : "@id" },
          "Ascending" : "ldp:Ascending",
          "Descending" : "ldp:Descending",
          "Page" : "ldp:Page",
          "pageSequence" : { "@id" : "ldp:pageSequence", "@type" : "@id" },
          "inbox" : { "@id" : "ldp:inbox", "@type" : "@id" },

          "ebucore" : "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#",
          "hasRelatedImage" : { "@id" : "ebucore:hasRelatedImage", "@type" : "@id" },
          "hasRelatedMediaFragment" : { "@id" : "ebucore:hasRelatedMediaFragment", "@type" : "@id" },

          "dc" : "http://purl.org/dc/",
          "dce" : "dc:elements/1.1/",
          "description" : { "@id" : "dce:description" },
          "publisher" : { "@id" : "dce:publisher" },
          "subject" : { "@id" : "dce:subject" },
          "dct" : "dc:terms/",
          "title" : { "@id" : "dct:title" },
          "dateSubmitted" : { "@id": "dct:dateSubmitted", "@type" : "XMLSchema:dateTime" },
          "modified" : { "@id" : "dct:modified", "@type" : "XMLSchema:dateTime" },
          "hasPart" : { "@id" : "dct:hasPart", "@container" : "@set", "@type" : "@id" },

          "foaf" : "http://xmlns.com/foaf/0.1/",
          "family_name" : { "@id" : "foaf:family_name" },
          "givenname" : { "@id" : "foaf:givenname" },

          "XMLSchema" : "http://www.w3.org/2001/XMLSchema#",
          "created" : { "@id" : "repository:created", "@type" : "XMLSchema:dateTime" },
          "created_by" : { "@id" : "created:By" },

          "repository" : "http://fedora.info/definitions/v4/repository#",
          "exportsAs" : { "@id" : "repository:exportsAs", "@type" : "@id" },
          "hasParent" : { "@id" : "repository:hasParent", "@type" : "@id" },
          "lastModified" : { "@id" : "repository:lastModified", "@type" : "XMLSchema:dateTime" },
          "lastModified_by" : { "@id" : "lastModified:By" },
          "numberOfChildren" : { "@id" : "repository:numberOfChildren", "@type" : "XMLSchema:long" },
          "writable" : { "@id" : "repository:writable", "@type" : "XMLSchema:boolean" },
          "hasTransactionProvider" : { "@id" : "repository:hasTransactionProvider", "@type" : "@id" },

          "fedora-model" : "info:fedora/fedora-system:def/model#",
          "rdf" : "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
          "hasModel" : { "@id" : "fedora-model:hasModel" }, //, "@type" : "rdf:type" },

          "fulcrum" : "http://fulcrum.org/ns#",
          "isbnEbook" : { "@id" : "fulcrum:isbnEbook" },
          "isbnSoftcover" : { "@id" : "fulcrum:isbnSoftcover" },

          "schema" : "http://schema.org/",
          "isbn" : { "@id" : "schema:isbn" },
          "sameAs" : { "@id" : "schema:sameAs" },
          "isPartOf" : { "@id" : "schema:isPartOf" },

          "relators" : "http://id.loc.gov/vocabulary/relators/",
          "dpt" : { "@id" : "relators:dpt" },
          "pbl" : { "@id" : "relators:pbl" },

          "relation" :"http://www.iana.org/assignments/relation/",
          "first" : { "@id" : "relation:first", "@type" : "@id" },
          "prev" : { "@id" : "relation:prev", "@type" : "@id" },
          "next" : { "@id" : "relation:next", "@type" : "@id" },
          "last" : { "@id" : "relation:last", "@type" : "@id" },

          "acl" : "http://www.w3.org/ns/auth/acl#",
          "accessControl" : { "@id" : "acl:accessControl", "@type" : "@id" },
          "accessTo" : { "@id" : "acl:accessTo", "@type" : "@id" },
          "agent" : { "@id" : "acl:agent", "@type" : "@id" },
          "mode" : { "@id" : "acl:mode", "@type" : "@id" },

          "person" : "http://projecthydra.org/ns/auth/person#",

          "pcdm" : "http://pcdm.org/models#",
          "hasMember" : { "@id" : "pcdm:hasMember", "@container" : "@set", "@type" : "@id" },
          "hasFile" : { "@id" : "pcdm:hasFile", "@type" : "@id" },

          "ore" : "http://www.openarchives.org/ore/",
          "oret" : "ore:terms/",
          "proxyFor" : { "@id" : "oret:proxyFor", "@type" : "@id" },
          "proxyIn" : { "@id" : "oret:proxyIn", "@type" : "@id" },

          "gk" : "http://www.gkostin.com/ns#",
          "gkf" : "http://www.gkostin.com/ns/Faraday#",
          "Response" : { "@id" : "gkf:Response" },
          "Response#request" : { "@id" : "gkf:Response:request", "@type" : "XMLSchema:string" },
          "Response#response" : { "@id" : "gkf:Response:response", "@type" : "XMLSchema:string" },
          "Response#status" : { "@id" : "gkf:Response:code", "@type" : "XMLSchema:long" },
          "Response#headers" : { "@id" : "gkf:Response:headers", "@type" : "XMLSchema:string" },
          "Response#body" : { "@id" : "gkf:Response:body", "@type" : "XMLSchema:string" }
        }
      }))['@context']

      json_ld = JSON::LD::API.compact(json_ld, context)

      json_ld.each do |key, value|
        case value
        when String
          json_ld[key].sub!(@base + '/', '') unless json_ld[key].frozen?
        when Array
          json_ld[key].map! { |item| item.frozen? ? item : item.is_a?(String) ? item.sub!(@base + '/', '') : item } # rubocop:disable Style/NestedTernaryOperator
        end
      end

      json_ld
    end

    private

      def connection
        @connection ||= Faraday.new(@base) do |conn|
          conn.headers = {
            accept: "application/ld+json",
            content_type: "application/ld+json"
          }
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end
  end
end
