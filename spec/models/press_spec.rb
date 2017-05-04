# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Press, type: :model do
  let(:press) { build(:press) }

  describe "to_param" do
    subject { press.to_param }
    let(:press) { build(:press, subdomain: 'umich') }

    it { is_expected.to eq 'umich' }
  end

  describe "roles" do
    subject { press.roles }
    it { is_expected.to eq [] }
  end
end
