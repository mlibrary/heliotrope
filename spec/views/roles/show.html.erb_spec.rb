# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "roles/show.html.erb", type: :view do
  let(:current_user) { create(:platform_admin) }

  before do
    @role = RolePresenter.new(current_user.roles.first, current_user, current_user)
    render
  end

  it { expect(rendered).to match(/Role/) }
end
