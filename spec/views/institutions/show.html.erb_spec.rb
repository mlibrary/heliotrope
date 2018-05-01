# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "institutions/show", type: :view do
  before do
    @institution = assign(
      :institution,
      Institution.create!(
        identifier: "Identifier",
        name: "Name",
        site: "Site",
        login: "Login"
      )
    )
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Identifier/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Site/)
    expect(rendered).to match(/Login/)
  end
end
