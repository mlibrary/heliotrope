# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "products/index", type: :view do
  before do
    assign(
      :products,
      [
        Product.create!(
          identifier: "Identifier1",
          purchase: "Purchase"
        ),
        Product.create!(
          identifier: "Identifier2",
          purchase: "Purchase"
        )
      ]
    )
  end

  it "renders a list of products" do
    render
    assert_select "div", text: "Identifier1".to_s, count: 1
    assert_select "div", text: "Identifier2".to_s, count: 1
  end
end
