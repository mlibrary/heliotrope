# Generated via
#  `rails generate curation_concerns:work Monograph`
module CurationConcerns
  class MonographForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::Monograph
    self.terms += [:press, :date_published, :isbn, :editor, :copyright_holder, :buy_url, :sub_brand]
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
  end
end
