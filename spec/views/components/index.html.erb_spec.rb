# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "components/index", type: :view do
  let(:file_set1) { double("file_set1", id: "123456789", parent: monograph1) }
  let(:file_set2) { double("file_set2", id: "987654321", parent: monograph2) }
  let(:monograph1) { double("monograph1", id: "111111111") }
  let(:monograph2) { double("monograph2", id: "222222222") }

  before do
    assign(
      :components,
      [
        Component.create!(
          handle: HandleService.path(file_set1.id)
        ),
        Component.create!(
          handle: HandleService.path(file_set2.id)
        )
      ]
    )
    allow(FileSet).to receive(:find).with(file_set1.id).and_return(file_set1)
    allow(FileSet).to receive(:find).with(file_set2.id).and_return(file_set2)
  end

  it "renders a list of components" do
    render
    assert_select "div", text: HandleService.path(file_set1.id), count: 1
    assert_select "div", text: HandleService.path(file_set2.id), count: 1
  end
end
