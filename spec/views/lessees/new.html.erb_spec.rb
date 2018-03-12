# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "lessees/new", type: :view do
  before do
    assign(
      :lessee,
      Lessee.new(
        identifier: "MyString"
      )
    )
  end

  it "renders new lessee form" do
    render
    assert_select "form[action=?][method=?]", lessees_path, "post" do
      assert_select "input[name=?]", "lessee[identifier]"
    end
  end
end
