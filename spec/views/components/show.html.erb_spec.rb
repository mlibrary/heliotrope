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
    allow(HandleService).to receive(:noid).with(@component.handle).and_return('noid')
    allow(HandleService).to receive(:url).with('noid').and_return('url')
  end

  it "renders attributes" do
    render
    expect(rendered).to match(/Handle/)
  end
end
