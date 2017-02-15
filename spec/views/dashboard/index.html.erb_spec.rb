require 'rails_helper'

RSpec.describe "dashboard/index.html.erb", type: :view do
  let(:user) { create(:platform_admin) }
  before do
    allow(view).to receive(:current_user).and_return(user)
    render
  end
  it { expect(rendered).to match(/Dashboard/) }
end
