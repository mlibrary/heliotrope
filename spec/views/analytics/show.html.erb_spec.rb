# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "analytics/show.html.erb", type: :view do
  let(:current_user) { create(:platform_admin) }
  before do
    @analytics = AnalyticsPresenter.new(current_user)
    render
  end
  it { expect(rendered).to match(/Analytics/) }
end
