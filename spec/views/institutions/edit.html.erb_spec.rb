# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "institutions/edit", type: :view do
  before do
    @institution = assign(
      :institution,
      Institution.create!(
        key: "MyString",
        name: "MyString",
        site: "MyString",
        login: "MyString"
      )
    )
  end

  it "renders the edit institution form" do
    render
    assert_select "form[action=?][method=?]", institution_path(@institution), "post" do
      assert_select "input[name=?]", "institution[key]"
      assert_select "input[name=?]", "institution[name]"
      assert_select "input[name=?]", "institution[site]"
      assert_select "input[name=?]", "institution[login]"
    end
  end
end
