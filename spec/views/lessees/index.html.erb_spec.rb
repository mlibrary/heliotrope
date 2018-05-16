# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "lessees/index", type: :view do
  before do
    assign(
      :lessees,
      [
        Lessee.create!(
          identifier: "Identifier1"
        ),
        Lessee.create!(
          identifier: "Identifier2"
        )
      ]
    )
  end

  it "renders a list of lessees" do
    render
    assert_select "div", text: "Identifier1".to_s, count: 1
    assert_select "div", text: "Identifier2".to_s, count: 1
  end
end
