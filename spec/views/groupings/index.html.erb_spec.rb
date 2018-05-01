# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "groupings/index", type: :view do
  before do
    assign(
      :groupings,
      [
        Grouping.create!(
          identifier: "Identifier1"
        ),
        Grouping.create!(
          identifier: "Identifier2"
        )
      ]
    )
  end

  it "renders a list of groupings" do
    render
    assert_select "div", text: "Identifier1".to_s, count: 1
    assert_select "div", text: "Identifier2".to_s, count: 1
  end
end
