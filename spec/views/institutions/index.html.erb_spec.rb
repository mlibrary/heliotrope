# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "institutions/index", type: :view do
  before do
    assign(
      :institutions,
      [
        Institution.create!(
          key: "Key",
          name: "Name",
          site: "Site",
          login: "Login"
        ),
        Institution.create!(
          key: "Key",
          name: "Name",
          site: "Site",
          login: "Login"
        )
      ]
    )
  end

  it "renders a list of institutions" do
    render
    assert_select "tr>td", text: "Key".to_s, count: 2
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: "Site".to_s, count: 2
    assert_select "tr>td", text: "Login".to_s, count: 2
  end
end
