# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "groupings/new", type: :view do
  before do
    assign(
      :grouping,
      Grouping.new(
        identifier: "MyString"
      )
    )
  end

  it "renders new grouping form" do
    render
    assert_select "form[action=?][method=?]", groupings_path, "post" do
      assert_select "input[name=?]", "grouping[identifier]"
    end
  end
end
