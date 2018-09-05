# frozen_string_literal: true

# Attribute mapping from ruby-style variable name to JSON key.
# def self.attribute_map
#   {
#       :'report_header' => :'Report_Header',
#       :'report_items' => :'Report_Items'
#   }
# end

# Attribute type mapping. SwaggerClient::COUNTERDatabaseReport
# def self.swagger_types
#   {
#       :'report_header' => :'SUSHIReportHeader',
#       :'report_items' => :'Array<COUNTERDatabaseUsage>'
#   }
# end

# Attribute type mapping. SwaggerClient::COUNTERItemReport
# def self.swagger_types
#   {
#       :'report_header' => :'SUSHIReportHeader',
#       :'report_items' => :'Array<COUNTERItemUsage>'
#   }
# end

# Attribute type mapping. SwaggerClient::COUNTERPlatformReport
# def self.swagger_types
#   {
#       :'report_header' => :'SUSHIReportHeader',
#       :'report_items' => :'Array<COUNTERPlatformUsage>'
#   }
# end

# Attribute type mapping. SwaggerClient::COUNTERTitleReport
# def self.swagger_types
#   {
#       :'report_header' => :'SUSHIReportHeader',
#       :'report_items' => :'Array<COUNTERTitleUsage>'
#   }
# end

json.key_format! ->(key) { @report.class.attribute_map[key.to_sym] }
json.extract! @report, :report_header, :report_items
