# frozen_string_literal: true

class SubBrand < ApplicationRecord
  belongs_to :press

  validates :press, presence: true
  validates :title, presence: true

  # A sub-brand can contain other sub-brands
  belongs_to :parent, class_name: 'SubBrand', optional: true
  has_many :sub_brands, foreign_key: 'parent_id'
  validate :cannot_contain_itself
  validate :cannot_contain_parent

  private

    def cannot_contain_itself
      return unless sub_brands.include?(self)
      errors.add(:sub_brands, "can't contain itself")
    end

    # Note: I'm calling sub_brands.to_a before checking the
    # relationship because otherwise the test returns incorrect
    # results in some situations.
    # Normally you would add an :inverse_of field to the
    # association, but that doesn't work in this case.
    # From the Rails documentation:
    # "For belongs_to associations, has_many inverse
    # associations are ignored."
    # http://guides.rubyonrails.org/association_basics.html#bi-directional-associations
    def cannot_contain_parent
      sub_brands.to_a
      return unless sub_brands.include?(parent)
      errors.add(:sub_brands, "can't contain its parent")
    end
end
