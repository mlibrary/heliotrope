require 'rails_helper'

RSpec.describe "dashboard/index.html.erb", type: :view do
  before { render }
  it { expect(rendered).to match(/Dashboard/) }
end
