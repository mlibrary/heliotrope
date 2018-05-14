# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "institutions/index", type: :view do
  before do
    assign(
      :institutions,
      [
        Institution.create!(
          identifier: "Identifier1",
          name: "Name",
          site: "Site",
          login: "Login"
        ),
        Institution.create!(
          identifier: "Identifier2",
          name: "Name",
          site: "Site",
          login: "Login"
        )
      ]
    )
  end

  it "renders a list of institutions" do
    render
    assert_select "div", text: "Identifier1".to_s, count: 1
    assert_select "div", text: "Identifier2".to_s, count: 1
    assert_select "div", text: "Name".to_s, count: 2
  end
end
