# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "fulcrum/show.html.erb", type: :view do
  let(:current_user) { create(:platform_admin) }
  let(:partial) { 'home' }
  before do
    allow(view).to receive(:current_user).and_return(current_user)
    @partial = partial
    render
  end
  it { expect(rendered).to match(/Home/) }
end
