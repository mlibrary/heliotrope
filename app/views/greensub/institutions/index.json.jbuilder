# frozen_string_literal: true

json.array! @institutions, partial: 'greensub/institutions/institution', as: :institution
