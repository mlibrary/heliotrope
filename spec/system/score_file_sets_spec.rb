# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Score FileSets and PDF reader", type: :system do
  let(:press) { create(:press, subdomain: Services.score_press) }
  let(:user) { create(:press_admin, press: press) }
  let(:score) do
    create(:score, press: press.subdomain,
                   user: user,
                   visibility: "open",
                   representative_id: cover.id,
                   title: ["A Title"],
                   creator: ["A Composer"],
                   octave_compass: ['2', '2.5', '3'],
                   solo: "yes",
                   amplified_electronics: ["Optional"],
                   musical_presentation: "Traditional concert",
                   edit_groups: ['admin', 'carillon_admin']) # <= this will get done in the actor later in HELIO-2918
  end
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) do
    create(:file_set, content: File.open(File.join(fixture_path, 'kitty.tif')),
                      creator: ["Ida No"],
                      title: ["Kitty"],
                      description: ["Just a file"],
                      extra_type_properties: { score_version: "eleventy-three" }.to_json,
                      edit_groups: ['admin', 'carillon_admin'])
  end
  let(:pdf) do
    create(:file_set, content: File.open(File.join(fixture_path, 'hello.pdf')),
                      title: ['PDF EBook'],
                      edit_groups: ['admin', 'carillon_admin']) # <= ditto.
  end

  before do
    sign_in user
    stub_out_redis
    score.ordered_members = [cover, file_set, pdf]
    score.save!
    cover.save!
    file_set.save!
    pdf.save!
  end

  it do
    visit score_catalog_path(score.id)

    expect(page).to have_content('A Title')

    click_on('Kitty')

    # Make sure the score specific file_set fields (like score_version) that are json in extra_type_properties
    # show up on the file_set page.
    expect(page).to have_content('Score version')
    expect(page).to have_content('eleventy-three')

    visit score_show_path(score.id)

    # Make sure FeaturedRepresentative can be set for the pdf
    # TODO: HELIO-2923
    # within_fieldset pdf.id do
    #   select('pdf_ebook', from: 'kind')
    #   click_on('Set')
    # end

    # Make sure the ereader loads.
    # TODO HELIO-2924
  end
end
