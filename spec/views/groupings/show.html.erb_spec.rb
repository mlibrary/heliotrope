# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "groupings/show", type: :view do
  before do
    @grouping = assign(
      :grouping,
      Grouping.create!(
        identifier: "Identifier"
      )
    )
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Identifier/)
  end
end
