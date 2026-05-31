# Default HAML templates used for generating output from the writer
module RDF::RDFa
  class Writer
    # The default set of HAML templates used for RDFa code generation
   BASE_HAML = {
     identifier: "base",
      # Document
      # Locals: language, title, prefix, base, subjects
      # Yield: subjects.each
      doc: %q(
        !!! XML
        !!! 5
        %html{**{xmlns: "http://www.w3.org/1999/xhtml", lang: lang, prefix: prefix}.compact}
          - if base || title
            %head
              - if base
                %base{**{href: base}.compact}
              - if title
                %title= title
          %body
            - subjects.map do |subject|
              != yield(subject)
      ),

      # Output for non-leaf resources
      # Note that @about may be omitted for Nodes that are not referenced
      #
      # If _rel_ and _resource_ are not nil, the tag will be written relative
      # to a previous subject. If _element_ is :li, the tag will be written
      # with <li> instead of <div>.
      #
      # Locals: subject, typeof, predicates, rel, element, inlist
      # Yield: predicates.each
      subject: %q(
        - if element == :li
          %li{**{rel: rel, resource: (about || resource), typeof: typeof, inlist: inlist}.compact}
            - if typeof
              %span.type!= typeof
            - predicates.each do |predicate|
              != yield(predicate)
        - else
          %div{**{rel: rel, resource: (about || resource), typeof: typeof, inlist: inlist}.compact}
            - if typeof
              %span.type!= typeof
            - predicates.each do |predicate|
              != yield(predicate)
      ),

      # Output for single-valued properties
      # Locals: predicate, object, inlist
      # Yields: object
      # If nil is returned, render as a leaf
      # Otherwise, render result
      property_value: %q(
        - if heading_predicates.include?(predicate) && object.literal?
          %h1{**{property: get_curie(predicate), content: get_content(object), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}= escape_entities(get_value(object))
        - else
          %div.property
            %span.label
              = get_predicate_name(predicate)
            - if res = yield(object)
              != res
            - elsif get_curie(object) == 'rdf:nil'
              %span{rel: get_curie(predicate), inlist: ''}
            - elsif object.node?
              %span{**{property: get_curie(predicate), resource: get_curie(object), inlist: inlist}.compact}= get_curie(object)
            - elsif object.uri?
              %a{**{property: get_curie(predicate), href: object.to_s, inlist: inlist}.compact}= object.to_s
            - elsif object.datatype == RDF.XMLLiteral
              %span{**{property: get_curie(predicate), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}<!= get_value(object)
            - else
              %span{**{property: get_curie(predicate), content: get_content(object), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}= escape_entities(get_value(object))
      ),

      # Output for multi-valued properties
      # Locals: predicate, :objects, :inlist
      # Yields: object for leaf resource rendering
      property_values:  %q(
        %div.property
          %span.label
            = get_predicate_name(predicate)
          %ul
            - objects.each do |object|
              - if res = yield(object)
                != res
              - elsif object.node?
                %li{**{property: get_curie(predicate), resource: get_curie(object), inlist: inlist}.compact}= get_curie(object)
              - elsif object.uri?
                %li
                  %a{**{property: get_curie(predicate), href: object.to_s, inlist: inlist}.compact}= object.to_s
              - elsif object.datatype == RDF.XMLLiteral
                %li{**{property: get_curie(predicate), lang: get_lang(object), datatype: get_curie(object.datatype), inlist: inlist}.compact}<!= get_value(object)
              - else
                %li{**{property: get_curie(predicate), content: get_content(object), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}= escape_entities(get_value(object))
      ),
    }

    # An alternative, minimal HAML template for RDFa code generation.
    # This version does not perform recursive object generation and does not attempt
    # to create human readable output.
    MIN_HAML = {
      identifier: "min",
      # Document
      # Locals: language, title, prefix, base, subjects
      # Yield: subjects.each
      doc: %q(
        !!! XML
        !!! 5
        %html{**{xmlns: "http://www.w3.org/1999/xhtml", lang: lang, prefix: prefix}.compact}
          - if base
            %head
              %base{*{href: base}.compact}
          %body
            - subjects.each do |subject|
              != yield(subject)
      ),

      # Output for non-leaf resources
      # Note that @about may be omitted for Nodes that are not referenced
      #
      # Locals: about, typeof, predicates, :inlist
      # Yield: predicates.each
      subject: %q(
        %div{**{rel: rel, resource: (about || resource), typeof: typeof}.compact}
          - predicates.each do |predicate|
            != yield(predicate)
      ),

      # Output for single-valued properties.
      # This version does not perform a recursive call, and renders all objects as leafs.
      # Locals: predicate, object, inlist
      # Yields: object
      # If nil is returned, render as a leaf
      # Otherwise, render result
      property_value: %q(
      - if res = yield(object)
        != res
      - elsif get_curie(object) == 'rdf:nil'
        %span{rel: get_curie(predicate), inlist: ''}
      - elsif object.node?
        %span{**{property: get_curie(predicate), resource: get_curie(object), inlist: inlist}.compact}= get_curie(object)
      - elsif object.uri?
        %a{**{property: get_curie(predicate), href: object.to_s, inlist: inlist}.compact}= object.to_s
      - elsif object.datatype == RDF.XMLLiteral
        %span{**{property: get_curie(predicate), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}<!= get_value(object)
      - else
        %span{**{property: get_curie(predicate), content: get_content(object), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}= escape_entities(get_value(object))
      )
    }

    DISTILLER_HAML = {
      identifier: "distiller",
      # Document
      # Locals: language, title, prefix, base, subjects
      # Yield: subjects.each
      doc: %q(
        !!! XML
        !!! 5
        %html{**{xmlns: "http://www.w3.org/1999/xhtml", lang: lang, prefix: prefix}.compact}
          - if base || title
            %head
              - if base
                %base{href: base}
              - if title
                %title= title
              %link{rel: "stylesheet", href: "http://rdf.greggkellogg.net/css/distiller.css", type: "text/css"}
              %script{src: "https://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js", type: "text/javascript"}
              %script{src: "http://rdf.greggkellogg.net/js/distiller.js", type: "text/javascript"}
          %body
            - if base
              %p= "RDFa serialization URI base: &lt;#{base}&gt;"
            - subjects.each do |subject|
              != yield(subject)
            %footer
              %p= "Written by <a href='https://rubygems.org/gems/rdf-rdfa'>RDF::RDFa</a> version #{RDF::RDFa::VERSION}"
      ),

      # Output for non-leaf resources
      # Note that @about may be omitted for Nodes that are not referenced
      #
      # If _rel_ and _resource_ are not nil, the tag will be written relative
      # to a previous subject. If _element_ is :li, the tag will be written
      # with <li> instead of <div>.
      #
      # Note that @rel and @resource can be used together, or @about and @typeof, but
      # not both.
      #
      # Locals: subject, typeof, predicates, rel, element, inlist
      # Yield: predicates.each
      subject: %q(
        - if element == :li
          %li{**{rel: rel, resource: (about || resource), typeof: typeof, inlist: inlist}.compact}
            - if typeof
              %span.type!= typeof
            %table.properties
              - predicates.each do |predicate|
                != yield(predicate)
        - elsif rel
          %td{**{rel: rel, resource: (about || resource), typeof: typeof, inlist: inlist}.compact}
            - if typeof
              %span.type!= typeof
            %table.properties
              - predicates.each do |predicate|
                != yield(predicate)
        - else
          %div{**{resource: (about || resource), typeof: typeof, inlist: inlist}.compact}
            - if typeof
              %span.type!= typeof
            %table.properties
              - predicates.each do |predicate|
                != yield(predicate)
      ),

      # Output for single-valued properties
      # Locals: predicate, object, inlist
      # Yields: object
      # If nil is returned, render as a leaf
      # Otherwise, render result
      property_value: %q(
        - if heading_predicates.include?(predicate) && object.literal?
          %h1{**{property: get_curie(predicate), content: get_content(object), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}= escape_entities(get_value(object))
        - else
          %tr.property
            %td.label
              = get_predicate_name(predicate)
            - if res = yield(object)
              != res
            - elsif get_curie(object) == 'rdf:nil'
              %td{rel: get_curie(predicate), inlist: ''}= "Empty"
            - elsif object.node?
              %td{**{property: get_curie(predicate), resource: get_curie(object), inlist: inlist}.compact}= get_curie(object)
            - elsif object.uri?
              %td
                %a{**{property: get_curie(predicate), href: object.to_s, inlist: inlist}.compact}= object.to_s
            - elsif object.datatype == RDF.XMLLiteral
              %td{**{property: get_curie(predicate), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}<!= get_value(object)
            - else
              %td{**{property: get_curie(predicate), content: get_content(object), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}= escape_entities(get_value(object))
      ),

      # Output for multi-valued properties
      # Locals: predicate, objects, inliste
      # Yields: object for leaf resource rendering
      property_values:  %q(
        %tr.property
          %td.label
            = get_predicate_name(predicate)
          %td
            %ul
              - objects.each do |object|
                - if res = yield(object)
                  != res
                - elsif object.node?
                  %li{**{property: get_curie(predicate), resource: get_curie(object), inlist: inlist}.compact}= get_curie(object)
                - elsif object.uri?
                  %li
                    %a{**{property: get_curie(predicate), href: object.to_s, inlist: inlist}.compact}= object.to_s
                - elsif object.datatype == RDF.XMLLiteral
                  %li{**{property: get_curie(predicate), lang: get_lang(object), datatype: get_curie(object.datatype), inlist: inlist}.compact}<!= get_value(object)
                - else
                  %li{**{property: get_curie(predicate), content: get_content(object), lang: get_lang(object), datatype: get_dt_curie(object), inlist: inlist}.compact}= escape_entities(get_value(object))
      ),
    }
    HAML_TEMPLATES = {base: BASE_HAML, min: MIN_HAML, distiller: DISTILLER_HAML}
    DEFAULT_HAML = BASE_HAML
  end
end
