require 'rails_helper'

RSpec.describe "users/show.html.erb", type: :view do
  let(:current_user) { create(:platform_admin) }
  before do
    @user = UserPresenter.new(current_user, current_user)
    render
  end
  it { expect(rendered).to match(/User/) }
end
