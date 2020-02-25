# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleDeposit, type: :model do
  subject(:deposit) { create(:handle_deposit) }

  it { expect(ValidationService.valid_noid?(deposit.noid)).to be true }
end
