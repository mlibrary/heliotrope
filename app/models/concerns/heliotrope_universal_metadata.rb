# frozen_string_literal: true

module HeliotropeUniversalMetadata
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    validate :date_published_format
    before_validation :maybe_convert_date_published_to_date_time, :maybe_set_date_published

    property :rightsholder, predicate: ::RDF::Vocab::DC.rightsHolder, multiple: false do |index|
      index.as :stored_searchable
    end

    # this tracks when/if PublishJob was run for this object, it acts as a very basic piece of "audit trail" metadata *only*,...
    # and not as any kind of citation publication date value
    property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
      index.as :stored_searchable
    end

    property :doi, predicate: ::RDF::Vocab::Identifiers.doi, multiple: false do |index|
      index.as :symbol
    end
    validates :doi, format: { without: /\Ahttp.*\z/,
                              message: "Don't use full doi link. Enter e.g. 10.3998/mpub.1234567.blah" }

    property :hdl, predicate: ::RDF::Vocab::Identifiers.hdl, multiple: false do |index|
      index.as :symbol
    end

    property :holding_contact, predicate: ::RDF::URI.new('http://fulcrum.org/ns#holdingContact'), multiple: false do |index|
      index.as :symbol
    end

    property :tombstone, predicate: ::RDF::URI.new('http://fulcrum.org/ns#tombstone'), multiple: false do |index|
      index.as :symbol
    end

    property :tombstone_message, predicate: ::RDF::URI.new('http://fulcrum.org/ns#tombstone_message'), multiple: false do |index|
      index.as :stored_searchable
    end

    private

      def maybe_set_date_published
        # conorom 20230203 `visibility_changed?` is literally the only `ActiveModel::Dirty` type method available in...
        # our current verion of `hydra-head`. More have since ben added. See https://github.com/samvera/hydra-head/pull/514
        # This logic works well enough, and the model specs around this should be thorough enough to catch all cases.
        if self.visibility_changed? && self.visibility == 'open' && self.date_published.blank?
          self.date_published = [Hyrax::TimeService.time_in_utc]
        end
      end

      def date_published_format
        if date_published.present? && self.date_published.first.instance_of?(String)
          begin
            DateTime.parse(date_published.first)
          rescue
            errors.add(:date_published, "Invalid DateTime value")
          end
        end
      end

      # catch values set via the datepicker and convert them from String to DateTime for consistency
      def maybe_convert_date_published_to_date_time
        if self.date_published.present? && self.date_published.first.instance_of?(String)
          begin
            self.date_published = [DateTime.parse(self.date_published.first)]
          rescue Date::Error
            ''
          end
        end
      end
  end
end
