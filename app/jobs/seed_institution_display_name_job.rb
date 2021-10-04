# frozen_string_literal: true

class SeedInstitutionDisplayNameJob < ApplicationJob
  def perform
    Greensub::Institution.all.each do |institution|
      next if institution.display_name.present?

      institution.display_name = institution.name
      institution.save
    end

    true
  end
end
