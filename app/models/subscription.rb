# frozen_string_literal: true

class Subscription < ApplicationRecord
  validates :subscriber, presence: true, allow_blank: false
  validates :publication, presence: true, allow_blank: false
  validates_uniqueness_of :subscriber, scope: :publication # rubocop:disable Rails/Validation
end
