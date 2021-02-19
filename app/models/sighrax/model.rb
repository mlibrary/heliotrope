# frozen_string_literal: true

module Sighrax
  class Model < Entity
    private_class_method :new

    def title
      Array(data['title_tesim']).first || super
    end

    def timestamp
      Array(data['timestamp']).first
    end

    def last_modified
      Time.parse(timestamp).utc
    rescue
      nil
    end

    def tombstone?
      expiration_date = Array(data['permissions_expiration_date_ssim']).first
      return false if expiration_date.blank?

      Date.parse(expiration_date) <= Time.now.utc.to_date
    end

    def deposited?
      Array(data['suppressed_bsi']).empty? ||
        Array(data['suppressed_bsi']).first.blank?
    end

    def published?(entity)
      deposited? && /open/i.match?(Array(data['visibility_ssi']).first)
    end

    protected

      def model_type
        Array(data['has_model_ssim']).first
      end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
