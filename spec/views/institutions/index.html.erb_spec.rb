# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "institutions/index", type: :view do
  before do
    assign(
      :institutions,
      [
        Institution.create!(
          identifier: "Identifier",
          name: "Name",
          site: "Site",
          login: "Login"
        ),
        Institution.create!(
          identifier: "Identifier",
          name: "Name",
          site: "Site",
          login: "Login"
        )
      ]
    )
  end

  it "renders a list of institutions" do
    render
    assert_select "div", text: "Name".to_s, count: 2
  end
end
