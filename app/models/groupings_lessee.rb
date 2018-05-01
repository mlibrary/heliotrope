# frozen_string_literal: true

class GroupingsLessee < ApplicationRecord
  belongs_to :grouping
  belongs_to :lessee
end
