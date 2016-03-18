require 'rails_helper'

RSpec.describe Press, type: :model do
  let(:press) { build(:press) }

  describe "to_param" do
    let(:press) { build(:press, subdomain: 'umich') }
    subject { press.to_param }
    it { is_expected.to eq 'umich' }
  end

  describe "roles" do
    subject { press.roles }
    it { is_expected.to eq [] }
  end
end
