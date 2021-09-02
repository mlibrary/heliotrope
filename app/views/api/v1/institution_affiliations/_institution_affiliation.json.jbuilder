# frozen_string_literal: true

json.extract! institution_affiliation, :id, :institution_id, :dlps_institution_id, :affiliation
json.url greensub_institution_affiliation_url(institution_affiliation, format: :json)
