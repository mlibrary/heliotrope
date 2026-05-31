module Hydra::PCDM::Validators
  class AncestorValidator
    def self.validate!(association, record)
      new(association.owner, record).validate!
    end

    attr_reader :owner, :record
    def initialize(owner, record)
      @owner = owner
      @record = record
    end

    def validate!
      return unless owner.ancestor?(record)
      raise ArgumentError, "#{record.class} with ID: #{record.id} failed to pass AncestorChecker validation"
    end
  end
end
