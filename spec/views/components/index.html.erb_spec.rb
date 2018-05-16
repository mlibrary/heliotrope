# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "components/index", type: :view do
  before do
    assign(
      :components,
      [
        Component.create!(
          handle: "Handle1"
        ),
        Component.create!(
          handle: "Handle2"
        )
      ]
    )
  end

  it "renders a list of components" do
    render
    assert_select "div", text: "Handle1".to_s, count: 1
    assert_select "div", text: "Handle2".to_s, count: 1
  end
end
