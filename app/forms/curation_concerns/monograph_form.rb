# Generated via
#  `rails generate curation_concerns:work Monograph`
module CurationConcerns
  class MonographForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::Monograph
    self.terms += [:press, :date_published, :isbn, :editor, :copyright_holder, :buy_url]
    self.required_fields += [:press]

    delegate :current_user, to: :current_ability

    # The possible values for the press selector drop-down.
    # @return [Hash] The press that this monograph belongs to.
    def select_press
      Hash[current_user.admin_presses.map { |press| [press.name, press.subdomain] }]
    end
  end
end
