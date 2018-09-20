# frozen_string_literal: true

json.array! @permits, partial: 'permits/permit', as: :permit
