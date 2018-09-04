# frozen_string_literal: true

# Attribute mapping from ruby-style variable name to JSON key.
# def self.attribute_map
#   {
#       :'description' => :'Description',
#       :'service_active' => :'Service_Active',
#       :'registry_url' => :'Registry_URL',
#       :'note' => :'Note',
#       :'alerts' => :'Alerts'
#   }
# end

# Attribute type mapping.
# def self.swagger_types
#   {
#       :'description' => :'String',
#       :'service_active' => :'BOOLEAN',
#       :'registry_url' => :'String',
#       :'note' => :'String',
#       :'alerts' => :'Array<SUSHIServiceStatusAlerts>'
#   }
# end

json.key_format! ->(key) { status.class.attribute_map[key.to_sym] }
json.extract! status, :description, :service_active, :registry_url, :note, :alerts
