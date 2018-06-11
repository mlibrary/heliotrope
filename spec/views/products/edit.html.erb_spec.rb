# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "products/edit", type: :view do
  before do
    @product = assign(
      :product,
      Product.create!(
        identifier: "MyString",
        name: "MyString",
        purchase: "MyString"
      )
    )
  end

  it "renders the edit product form" do
    render
    assert_select "form[action=?][method=?]", product_path(@product), "post" do
      assert_select "input[name=?]", "product[identifier]"
      assert_select "input[name=?]", "product[purchase]"
    end
  end
end
