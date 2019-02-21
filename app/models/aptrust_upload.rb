# frozen_string_literal: true

class AptrustUpload < ApplicationRecord
  validates :noid, presence: { message: "noid must be given" }
  validates :noid, uniqueness: true, on: :create
  validates :bag_status, presence: true
  validates :s3_status, presence: true
  validates :apt_status, presence: true
  validates :bag_status, numericality: { only_integer: true }
  validates :s3_status, numericality: { only_integer: true }
  validates :apt_status, numericality: { only_integer: true }
end
