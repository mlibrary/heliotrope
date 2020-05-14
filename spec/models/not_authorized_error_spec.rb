# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotAuthorizedError do
  it { is_expected.to be_a StandardError }
end
