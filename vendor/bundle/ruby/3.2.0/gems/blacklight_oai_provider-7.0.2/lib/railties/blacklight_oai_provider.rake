namespace :blacklight_oai_provider do
  # Copied index seeding task from newer versions of Blacklight
  namespace :index do
    desc "Put sample data into solr"
    task seed: [:environment] do
      require 'yaml'

      docs = YAML.safe_load(File.open(File.join(BlacklightOaiProvider.root, 'solr', 'sample_solr_documents.yml')))
      conn = Blacklight.default_index.connection
      conn.add docs
      conn.commit
    end
  end
end
