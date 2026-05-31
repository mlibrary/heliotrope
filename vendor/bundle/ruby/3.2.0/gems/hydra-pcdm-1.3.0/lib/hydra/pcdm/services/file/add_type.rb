module Hydra::PCDM
  module AddTypeToFile
    # This adds an additional RDF type to an exsiting Hydra::PCDM::File
    #
    # @param [Hydra::PCDM::File] the file object you want to add it to
    # @param [RDF::URI] term you want to add as the type
    #
    # @return [Hydra::PCDM::File] the updated file

    def self.call(file, uri)
      t = file.metadata_node.get_values(:type)
      return file if t.include?(uri)
      t << uri
      file.metadata_node.set_value(:type, t)
      file
    end
  end
end
