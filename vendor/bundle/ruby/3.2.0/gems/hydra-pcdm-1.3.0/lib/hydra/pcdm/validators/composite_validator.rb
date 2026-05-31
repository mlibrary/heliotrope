module Hydra::PCDM::Validators
  ##
  # Object which acts as one validator but delegates to many.
  class CompositeValidator
    attr_reader :validators

    def initialize(*validators)
      @validators = validators.compact
    end

    def validate!(reflection, record)
      validators.each do |validator|
        validator.validate!(reflection, record)
      end
    end
  end
end
