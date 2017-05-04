# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "dashboard/index.html.erb", type: :view do
  let(:current_user) { create(:platform_admin) }
  before do
    allow(view).to receive(:current_user).and_return(current_user)
    render
  end
  it { expect(rendered).to match(/Place holder/) }
end
