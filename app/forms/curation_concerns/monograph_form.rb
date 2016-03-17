# Generated via
#  `rails generate curation_concerns:work Monograph`
module CurationConcerns
  class MonographForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::Monograph
    self.terms += [:date_published, :isbn, :editor, :copyright_holder, :buy_url]
  end
end
