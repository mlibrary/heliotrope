# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "products/new", type: :view do
  before do
    assign(
      :product,
      Product.new(
        identifier: "MyString"
      )
    )
  end

  it "renders new product form" do
    render
    assert_select "form[action=?][method=?]", products_path, "post" do
      assert_select "input[name=?]", "product[identifier]"
    end
  end
end
