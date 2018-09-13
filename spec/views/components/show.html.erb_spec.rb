# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "components/show", type: :view do
  let(:file_set) { double('file_set', id: 'file_set') }
  let(:monograph) { double('monograph', id: 'monograph') }

  before do
    @component = assign(
      :component,
      Component.create!(
        handle: "Handle"
      )
    )
    allow(HandleService).to receive(:noid).with(@component.handle).and_return(file_set.id)
    allow(HandleService).to receive(:url).with(file_set.id).and_return('url')
    allow(FileSet).to receive(:find).with(file_set.id).and_return(file_set)
    allow(file_set).to receive(:parent).and_return(monograph)
  end

  it "renders attributes" do
    render
    expect(rendered).to match(/Handle/)
  end
end
