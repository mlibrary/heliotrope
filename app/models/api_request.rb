# frozen_string_literal: true

class APIRequest < ApplicationRecord
  belongs_to :user, optional: true
end
