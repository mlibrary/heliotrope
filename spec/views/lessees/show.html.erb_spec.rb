# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "lessees/show", type: :view do
  before do
    @lessee = assign(
      :lessee,
      Lessee.create!(
        identifier: "Identifier"
      )
    )
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Identifier/)
  end
end
