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
    allow(HandleService).to receive(:object).with(@component.handle).and_return(@component)
    allow(HandleService).to receive(:url).with(@component).and_return("http://www.example.com")
  end

  it "renders attributes" do
    render
    expect(rendered).to match(/Handle/)
  end
end
