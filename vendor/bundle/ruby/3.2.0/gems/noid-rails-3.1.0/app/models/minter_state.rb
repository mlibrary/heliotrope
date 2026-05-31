# frozen_string_literal: true

class MinterState < ApplicationRecord
  validates :namespace, presence: true, uniqueness: true
  validates :template, presence: true
  validates :template, format: { with: Object.const_get('Noid::Template::VALID_PATTERN'), message: 'value fails regex' }

  # Creates an initial row for the namespace.
  # @return [MinterState] the initial minter state
  def self.seed!(namespace:, template:)
    create!(
      namespace: namespace,
      template: template
    )
  end
end
