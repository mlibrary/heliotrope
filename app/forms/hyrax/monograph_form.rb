# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
module Hyrax
  class MonographForm < Hyrax::Forms::WorkForm
    self.model_class = ::Monograph
    # Hyrax::BasicMetadata fields are already included
    self.terms -= %i[keyword related_url source based_near rights_statement]
    # these will hold their order, bearing in mind that required_fields are automatically removed first
    self.terms += %i[press creator_display series buy_url isbn doi hdl copyright_holder open_access funder
                     holding_contact location section_titles]

    self.required_fields = %i[title press creator publisher date_created location]
    self.required_fields -= %i[keyword rights]

    # force some order to group items by relation and importance
    self.terms.delete_at(self.terms.index(:description))
    self.terms = self.terms.insert(self.terms.index(:contributor) - 1, :description)
    self.terms.delete_at(self.terms.index(:creator_display))
    self.terms = self.terms.insert(self.terms.index(:contributor) + 1, :creator_display)
    self.terms.delete_at(self.terms.index(:identifier))
    self.terms = self.terms.insert(self.terms.index(:hdl) + 1, :identifier)
    self.terms.delete_at(self.terms.index(:license))
    self.terms = self.terms.insert(self.terms.index(:copyright_holder), :license)

    delegate :current_user, to: :current_ability

    # The possible values for the press selector drop-down.
    # @return [Hash] The press that this monograph belongs to.
    def select_press
      Hash[current_user.admin_presses.map { |press| [press.name, press.subdomain] }]
    end

    def select_files
      # We only want FileSets here, not any other models, see story #174
      # Use model.file_set_ids, not model.member_ids
      file_sets ||=
        PresenterFactory.build_for(ids: model.file_set_ids, presenter_class: Hyrax::FileSetPresenter, presenter_args: current_ability)
      Hash[file_sets.map { |file| [file.to_s, file.id] }]
    end

    # RE: below methods, see https://samvera.github.io/customize-metadata-other-customizations.html
    def self.multiple?(field)
      if %i[title description creator contributor publisher date_created license].include? field.to_sym
        false
      else
        super
      end
    end

    def self.model_attributes(_nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      attrs = super
      attrs[:title] = Array(attrs[:title]) if attrs[:title]
      attrs[:description] = Array(attrs[:description]) if attrs[:description]
      attrs[:creator] = Array(attrs[:creator]) if attrs[:creator]
      attrs[:contributor] = Array(attrs[:contributor]) if attrs[:contributor]
      attrs[:publisher] = Array(attrs[:publisher]) if attrs[:publisher]
      attrs[:date_created] = Array(attrs[:date_created]) if attrs[:date_created]
      attrs[:license] = Array(attrs[:license]) if attrs[:license]
      attrs
    end

    def title
      super.first || ""
    end

    def creator
      super.first || ""
    end

    def contributor
      super.first || ""
    end

    def description
      super.first || ""
    end

    def publisher
      super.first || ""
    end

    def date_created
      super.first || ""
    end

    def license
      super.first || ""
    end
  end
end
