# Generated via
#  `rails generate curation_concerns:work Monograph`
module CurationConcerns
  class MonographForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::Monograph
    self.terms += [:press, :date_published, :isbn, :editor, :copyright_holder, :buy_url, :sub_brand, :creator_family_name, :creator_given_name]
    self.required_fields += [:press]

    delegate :current_user, to: :current_ability

    # The possible values for the press selector drop-down.
    # @return [Hash] The press that this monograph belongs to.
    def select_press
      Hash[current_user.admin_presses.map { |press| [press.name, press.subdomain] }]
    end

    def select_sub_brand
      presses = if press.blank?
                  current_user.admin_presses
                else
                  Press.where(subdomain: press)
                end

      Hash[presses.map(&:sub_brands).flatten.map { |brand| [brand.title, brand.id] }]
    end

    def select_files
      # We only want FileSets here, not Sections see story #174
      # Use model.file_set_ids, not model.member_ids
      file_sets ||=
        PresenterFactory.build_presenters(model.file_set_ids, FileSetPresenter, current_ability)
      Hash[file_sets.map { |file| [file.to_s, file.id] }]
    end
  end
end
