# frozen_string_literal: true

# Attribute mapping from ruby-style variable name to JSON key.
# def self.attribute_map
#   {
#       :'report_name' => :'Report_Name',
#       :'report_id' => :'Report_ID',
#       :'release' => :'Release',
#       :'report_description' => :'Report_Description',
#       :'path' => :'Path'
#   }
# end

# Attribute type mapping.
# def self.swagger_types
#   {
#       :'report_name' => :'String',
#       :'report_id' => :'String',
#       :'release' => :'String',
#       :'report_description' => :'String',
#       :'path' => :'String'
#   }
# end

json.key_format! ->(key) { report.class.attribute_map[key.to_sym] }
json.extract! report, :report_name, :report_id, :release, :report_description, :path
