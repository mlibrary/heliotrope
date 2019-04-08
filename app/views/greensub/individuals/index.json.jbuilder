# frozen_string_literal: true

json.array! @individuals, partial: 'greensub/individuals/individual', as: :individual
