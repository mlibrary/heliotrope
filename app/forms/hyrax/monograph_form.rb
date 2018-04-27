# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
module Hyrax
  class MonographForm < Hyrax::Forms::WorkForm
    self.model_class = ::Monograph
    self.terms += %i[press creator_display date_published isbn isbn_paper isbn_ebook hdl doi
                     primary_editor_family_name primary_editor_given_name editor copyright_holder buy_url
                     creator_family_name creator_given_name section_titles]
    self.terms -= %i[creator keyword identifier related_url source]

    self.required_fields = %i[title press creator_family_name creator_given_name description
                              publisher date_created]
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
  end
end
