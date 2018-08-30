# frozen_string_literal: true

# Attribute mapping from ruby-style variable name to JSON key.
# def self.attribute_map
#   {
#       :'customer_id' => :'Customer_ID',
#       :'requestor_id' => :'Requestor_ID',
#       :'name' => :'Name',
#       :'notes' => :'Notes',
#       :'institution_id' => :'Institution_ID'
#   }
# end

# Attribute type mapping.
# def self.swagger_types
#   {
#       :'customer_id' => :'String',
#       :'requestor_id' => :'String',
#       :'name' => :'String',
#       :'notes' => :'String',
#       :'institution_id' => :'Array<SUSHIOrgIdentifiers>'
#   }
# end

json.key_format! ->(key) { member.class.attribute_map[key.to_sym] }
json.extract! member, :customer_id, :requestor_id, :name, :notes, :institution_id
