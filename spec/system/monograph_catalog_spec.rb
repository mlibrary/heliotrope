# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Show a monograph", type: :system do # rubocop:disable RSpec/DescribeClass
  let(:cover) { create(:public_file_set, title: ["cover"], content: File.open(File.join(fixture_path, 'kitty.tif'))) }
  let(:monograph) do
    m = build(:public_monograph, creator_family_name: "Shakespeare",
                                 creator_given_name: "William",
                                 description: ["This is the description"],
                                 representative_id: cover.id)
    m.ordered_members << cover
    m.save!
    m
  end

  let(:file_set1) { create(:public_file_set, title: ["Miranda"]) }
  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))
      f.original_name = 'miranda.jpg'
      f.mime_type = 'image/jpeg'
      f.save!
    end
  end

  before do
    allow(file_set1).to receive(:original_file).and_return(file)
    monograph.ordered_members << file_set1
    monograph.save!
  end

  # Comment this method out to see screenshots on failures in tmp/screenshots
  def take_failed_screenshot
    false
  end

  pending "is accessible" do
    visit monograph_catalog_path(monograph)
    # This isn't quite right yet. I'd like to see the thumbnails for the file_sets
    # but I'm not sure how to stub/mock them yet.
    expect(page).to be_accessible.according_to :wcag2a, :section508
  end
end
