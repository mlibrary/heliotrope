# frozen_string_literal: true

module Sighrax
  class Model < Entity
    private_class_method :new

    def children
      []
    end

    def deposited?
      return true if vector('suppressed_bsi').empty?

      scalar('suppressed_bsi').blank?
    end

    def modified
      Time.parse(scalar('date_modified_dtsi')).utc
    rescue StandardError => _e
      nil
    end

    def parent
      Entity.null_entity
    end

    def published?
      deposited? && /open/i.match?(scalar('visibility_ssi'))
    end

    def publisher
      Publisher.from_subdomain(scalar('press_tesim'))
    end

    def timestamp
      Time.parse(scalar('timestamp')).utc
    rescue StandardError => _e
      nil
    end

    def title
      scalar('title_tesim') || super
    end

    def tombstone?
      return false if scalar('permissions_expiration_date_ssim').blank?

      return true if Date.parse(scalar('permissions_expiration_date_ssim')) <= Time.now.utc.to_date

      false
    end

    protected

      def model_type
        scalar('has_model_ssim')
      end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
