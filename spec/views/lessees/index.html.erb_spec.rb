# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "lessees/index", type: :view do
  before do
    assign(
      :lessees,
      [
        Lessee.create!(
          identifier: "Identifier"
        ),
        Lessee.create!(
          identifier: "Identifier"
        )
      ]
    )
  end

  it "renders a list of lessees" do
    render
    assert_select "tr>td", text: "Identifier".to_s, count: 2
  end
end
