# frozen_string_literal: true

Blacklight::AccessControls.configure do |config|
  # This specifies the solr field names of permissions-related fields.
  # The default fields used are shown below, if you index your permissions to other fields update the configuration below.
  # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
  #
  # config.discover_group_field = Solrizer.solr_name("discover_access_group", :symbol)
  # config.discover_user_field  = Solrizer.solr_name("discover_access_person", :symbol)
  # config.read_group_field     = Solrizer.solr_name("read_access_group", :symbol)
  # config.read_user_field      = Solrizer.solr_name("read_access_person", :symbol)
  # config.download_group_field = Solrizer.solr_name("download_access_group", :symbol)
  # config.download_user_field  = Solrizer.solr_name("dowload_access_person", :symbol)
  #
  # specify the user model
  # config.user_model = 'User'
end
