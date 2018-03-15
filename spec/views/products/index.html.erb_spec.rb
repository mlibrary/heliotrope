# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "products/index", type: :view do
  before do
    assign(
      :products,
      [
        Product.create!(
          identifier: "Identifier"
        ),
        Product.create!(
          identifier: "Identifier"
        )
      ]
    )
  end

  it "renders a list of products" do
    render
    assert_select "tr>td", text: "Identifier".to_s, count: 2
  end
end
