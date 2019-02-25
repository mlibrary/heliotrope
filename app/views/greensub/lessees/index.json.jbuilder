# frozen_string_literal: true

json.array! @lessees, partial: 'lessees/lessee', as: :lessee
