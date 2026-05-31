require 'hydra/works/version'
require 'hydra/pcdm'
require 'hydra/derivatives'
require 'rdf/vocab'

module Hydra
  module Works
    extend ActiveSupport::Autoload

    autoload :VirusScanner

    class << self
      class_attribute :default_system_virus_scanner
      self.default_system_virus_scanner = VirusScanner
    end

    module Vocab
      extend ActiveSupport::Autoload
      eager_autoload do
        autoload :WorksTerms
      end
    end

    autoload_under 'models/concerns/file_set' do
      autoload :Derivatives
      autoload :MimeTypes
      autoload :ContainedFiles
      autoload :VersionedContent
      autoload :VirusCheck
    end

    autoload :Characterization
    autoload :NotFileSetValidator
    autoload :NotCollectionValidator

    autoload_under 'models' do
      autoload :Collection
      autoload :FileSet
      autoload :Work
    end

    autoload_under 'models/concerns' do
      autoload :CollectionBehavior
      autoload :FileSetBehavior
      autoload :WorkBehavior
    end

    autoload_under 'services' do
      autoload :VirusCheckerService
      autoload :AddFileToFileSet
      autoload :AddExternalFileToFileSet
      autoload :UploadFileToFileSet
      autoload :PersistDerivative
      autoload :CharacterizationService
      autoload :DetermineMimeType
      autoload :DetermineOriginalName
    end

    ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas +=
      [
        Characterization::AudioSchema,
        Characterization::BaseSchema,
        Characterization::DocumentSchema,
        Characterization::ImageSchema,
        Characterization::VideoSchema
      ]
  end
end
