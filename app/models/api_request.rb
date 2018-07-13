# frozen_string_literal: true

class APIRequest < ApplicationRecord
  belongs_to :user, optional: true

  self.per_page = 20
end
