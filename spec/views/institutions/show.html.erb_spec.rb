# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "institutions/show", type: :view do
  before do
    @institution = assign(
      :institution,
      Institution.create!(
        key: "Key",
        name: "Name",
        site: "Site",
        login: "Login"
      )
    )
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Key/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Site/)
    expect(rendered).to match(/Login/)
  end
end
