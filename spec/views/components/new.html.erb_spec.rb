# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "components/new", type: :view do
  before do
    assign(
      :component,
      Component.new(
        handle: "MyString"
      )
    )
  end

  it "renders new component form" do
    render
    assert_select "form[action=?][method=?]", components_path, "post" do
      assert_select "input[name=?]", "component[handle]"
    end
  end
end
