# frozen_string_literal: true

json.array! @individuals, partial: 'individuals/individual', as: :individual
