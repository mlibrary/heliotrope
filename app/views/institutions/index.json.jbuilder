# frozen_string_literal: true

json.array! @institutions, partial: 'institutions/institution', as: :institution
