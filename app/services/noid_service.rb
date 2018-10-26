# frozen_string_literal: true

class NoidService
  private_class_method :new

  TYPE = %i[monograph file_set unknown object null_object].freeze

  attr_reader :noid, :type, :model

  # Class Methods

  def self.from_noid(noid) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    noid = noid&.to_s
    return null_object unless /^[[:alnum:]]{9}$/.match?(noid)
    model = begin
              ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
            rescue StandardError => _e
              nil
            end
    return null_object if model.blank?
    model_type = model["has_model_ssim"]&.first
    type = if model_type.blank?
             :object
           elsif /Monograph/i.match?(model_type)
             :mongraph
           elsif /FileSet/i.match?(model_type)
             :file_set
           else
             :unknown
           end
    new(noid, type, model)
  end

  def self.null_object
    NoidServiceNullObject.send(:new)
  end

  # Instance Methods

  def valid?
    !instance_of?(NoidServiceNullObject)
  end

  def title
    model["title_tesim"]&.first || noid
  end

  private

    def initialize(noid, type, model)
      @noid = noid
      @type = type
      @model = model
    end
end

class NoidServiceNullObject < NoidService
  private_class_method :new

  private

    def initialize
      super('null_noid', :null_object, {})
    end
end
