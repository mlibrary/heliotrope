# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "institutions/new", type: :view do
  before do
    assign(
      :institution,
      Institution.new(
        identifier: "MyString",
        name: "MyString",
        site: "MyString",
        login: "MyString"
      )
    )
  end

  it "renders new institution form" do
    render
    assert_select "form[action=?][method=?]", institutions_path, "post" do
      assert_select "input[name=?]", "institution[identifier]"
      assert_select "input[name=?]", "institution[name]"
      assert_select "input[name=?]", "institution[site]"
      assert_select "input[name=?]", "institution[login]"
    end
  end
end
