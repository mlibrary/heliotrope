# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "products/show", type: :view do
  before do
    @product = assign(
      :product,
      Product.create!(
        identifier: "Identifier",
        name: "Name",
        purchase: "Purchase"
      )
    )
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Identifier/)
    expect(rendered).to match(/Purchase/)
  end
end
