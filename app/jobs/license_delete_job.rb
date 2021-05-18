# frozen_string_literal: true

class LicenseDeleteJob < ApplicationJob
  def perform
    Greensub::License.where(type: '').each do |license|
      grants = Checkpoint::DB::Grant
                 .where(credential_type: 'License')
                 .where(credential_id: license.id)
      grants.each do |grant|
        grant.delete
      end
      license.destroy
    end

    Greensub::License.where(type: 'Greensub::License').each do |license|
      grants = Checkpoint::DB::Grant
                 .where(credential_type: 'License')
                 .where(credential_id: license.id)
      grants.each do |grant|
        grant.delete
      end
      license.destroy
    end
  end
end
