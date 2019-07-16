# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AptrustDeposit, type: :model do
  subject(:deposit) { create(:aptrust_deposit) }

  it { expect(ValidationService.valid_noid?(deposit.noid)).to be true }
end
