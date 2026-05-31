# Base class for Field/DynamicField/FieldType
module SimpleSolrClient
  class Schema
    class Field_or_Type

      include Comparable
      attr_accessor :name,
                    :type_name


      # Take in a hash, and set anything in it that we recognize.
      # Sloppy from a data point of view, but make for easy
      # duplication and creation from xml/json

      def initialize(h = {})
        @attributes = {}
        h.each_pair do |k, v|
          begin
            self[k] = v
          rescue
          end
        end
      end

      TEXT_ATTR_MAP = {
        :name                   => 'name',
        :type_name              => 'type',
        :precision_step         => 'precisionStep',
        :position_increment_gap => 'positionIncrementGap'
      }

      BOOL_ATTR_MAP = {
        :stored            => 'stored',
        :indexed           => 'indexed',
        :multi             => 'multiValued',
        :multivalued       => 'multiValued',
        :multiValued       => 'multiValued',
        :multi_valued      => 'multiValued',
        :sort_missing_last => 'sortMissingLast',
        :docvalues         => 'docValues',
        :docValues         => 'docvalues',
        :doc_values        => 'docvalues',
      }




      def ==(other)
        if other.respond_to? :name
          name == other.name and type_name == other.type_name
        else
          name == other
        end
      end


      def self.new_from_solr_hash(h)
        f = self.new

        TEXT_ATTR_MAP.merge(BOOL_ATTR_MAP).each_pair do |field, xmlattr|
          define_method(field.to_sym) do
            self[field.to_sym]
          end
          f[field] = h[xmlattr]
        end

        # Make some "method?" for the boolean attributes
        BOOL_ATTR_MAP.keys.each do |methname|
          q_methname = ((methname.to_s) + '?').to_sym
          alias_method q_methname, methname
        end
        
        # Set the name "manually" to force the
        # matcher
        f.name = h['name']
        f
      end


      # Reverse the process to get XML
      def to_xml_node
        doc ||= Nokogiri::XML::Document.new
        xml = xml_node(doc)
        TEXT_ATTR_MAP.merge(BOOL_ATTR_MAP).each_pair do |field, xmlattr|
          iv           = instance_variable_get("@#{field}".to_sym)
          xml[xmlattr] = iv unless iv.nil?
        end
        xml
      end

      def to_xml
        to_xml_node.to_xml
      end

      # Allow access to methods via [], for easy looping
      def [](k)
        @attributes[k.to_sym]
      end

      def []=(k, v)
        @attributes[k.to_sym]  = v
      end


      # Make a hash out of it, for easy feeding back into another call to #new
      def to_h
        @attributes
      end

    end
  end
end
