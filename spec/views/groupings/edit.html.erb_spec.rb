# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "groupings/edit", type: :view do
  before do
    @grouping = assign(
      :grouping,
      Grouping.create!(
        identifier: "MyString"
      )
    )
  end

  it "renders the edit grouping form" do
    render
    assert_select "form[action=?][method=?]", grouping_path(@grouping), "post" do
      assert_select "input[name=?]", "grouping[identifier]"
    end
  end
end
