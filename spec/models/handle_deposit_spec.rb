# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleDeposit, type: :model do
  subject(:deposit) { create(:handle_deposit) }

  # not all handle values will look like this, or contain a 9-digit NOID at all, but the standard Fulcrum ones will
  it { expect(ValidationService.valid_noid?(deposit.handle[-9..-1])).to be true }
end
