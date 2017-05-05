# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "roles/index2.html.erb", type: :view do
  let(:current_user) { create(:platform_admin) }
  before do
    @roles = RolesPresenter.new(current_user, current_user)
    render
  end
  it { expect(rendered).to match(/Roles/) }
end
