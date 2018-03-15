# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "lessees/edit", type: :view do
  before do
    @lessee = assign(
      :lessee,
      Lessee.create!(
        identifier: "MyString"
      )
    )
  end

  it "renders the edit lessee form" do
    render
    assert_select "form[action=?][method=?]", lessee_path(@lessee), "post" do
      assert_select "input[name=?]", "lessee[identifier]"
    end
  end
end
