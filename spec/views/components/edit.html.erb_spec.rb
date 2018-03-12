# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "components/edit", type: :view do
  before do
    @component = assign(
      :component,
      Component.create!(
        handle: "MyString"
      )
    )
  end

  it "renders the edit component form" do
    render

    assert_select "form[action=?][method=?]", component_path(@component), "post" do
      assert_select "input[name=?]", "component[handle]"
    end
  end
end
