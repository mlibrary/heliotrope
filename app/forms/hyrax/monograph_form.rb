# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
module Hyrax
  class MonographForm < Hyrax::Forms::WorkForm
    self.model_class = ::Monograph
    self.terms += %i[press creator_display date_created isbn isbn_paper isbn_ebook hdl doi
                     primary_editor_family_name primary_editor_given_name editor copyright_holder buy_url
                     creator_family_name creator_given_name section_titles location]
    self.terms -= %i[creator keyword identifier related_url source based_near rights_statement license]

    self.required_fields = %i[title press creator_family_name creator_given_name description publisher date_created
                              location]
    self.required_fields -= %i[creator keyword rights]

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
      if %i[title description publisher date_created].include? field.to_sym
        false
      else
        super
      end
    end

    def self.model_attributes(_)
      attrs = super
      attrs[:title] = Array(attrs[:title]) if attrs[:title]
      attrs[:description] = Array(attrs[:description]) if attrs[:description]
      attrs[:publisher] = Array(attrs[:publisher]) if attrs[:publisher]
      attrs[:date_created] = Array(attrs[:date_created]) if attrs[:date_created]
      # heliotrope fields that shouldn't have been multi
      attrs
    end

    def title
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

    # TODO: if these fields are sticking around then their cardinality should be "changed"
    # def isbn
    #   super.first || ""
    # end
    #
    # def isbn_paper
    #   super.first || ""
    # end
    #
    # def isbn_ebook
    #   super.first || ""
    # end
  end
end
