# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "components/show", type: :view do
  before do
    @component = assign(
      :component,
      Component.create!(
        handle: "Handle"
      )
    )
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Handle/)
  end
end
