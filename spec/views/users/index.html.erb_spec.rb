# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "users/index.html.erb", type: :view do
  let(:current_user) { create(:platform_admin) }

  before do
    @users = UsersPresenter.new(current_user)
    render
  end

  it { expect(rendered).to match(/Users/) }
end
