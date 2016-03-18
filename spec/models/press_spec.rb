require 'rails_helper'

RSpec.describe Press, type: :model do
  describe "to_param" do
    let(:press) { build(:press, subdomain: 'umich') }
    subject { press.to_param }
    it { is_expected.to eq 'umich' }
  end
end
