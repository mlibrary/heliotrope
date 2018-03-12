# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "components/index", type: :view do
  before do
    assign(
      :components,
      [
        Component.create!(
          handle: "Handle"
        ),
        Component.create!(
          handle: "Handle"
        )
      ]
    )
  end

  it "renders a list of components" do
    render
    assert_select "tr>td", text: "Handle".to_s, count: 2
  end
end
