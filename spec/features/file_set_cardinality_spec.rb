# frozen_string_literal: true

require 'rails_helper'

feature 'FileSet Cardinality' do
  # See #645
  # We want to assert that the file_set fields that we have in fedora, solr and forms
  # have the same cardinality: the field is multi-valued across everything or not.
  # Right now it seems to be a bit of a mixture. Maybe that's ok as long as we have
  # this test to assert what's true?
  let(:press) { create(:press, subdomain: 'umich') }
  let(:user) { create(:platform_admin) }
  let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
  let(:cover) { create(:file_set, allow_display_after_expiration: "lo-res",
                                  allow_download: "yes",
                                  allow_download_after_expiration: "no",
                                  allow_hi_res: "yes",
                                  alt_text: ["This is the alt text"],
                                  book_needs_handles: "yes",
                                  caption: ["This is the caption"],
                                  content_type: ["drawing", "illustration"],
                                  copyright_holder: "This is the © Copyright Holder",
                                  copyright_status: "in-copyright",
                                  credit_line: "Copyright by Some Person...",
                                  date_published: ["2017-01-01"],
                                  display_date: ["circa. 2000"],
                                  doi: "",
                                  exclusive_to_platform: "yes",
                                  external_resource: "no",
                                  ext_url_doi_or_handle: "Handle",
                                  hdl: "",
                                  holding_contact: "Some museum or something somewhere",
                                  keywords: ["dogs", "cats", "fish"],
                                  permissions_expiration_date: "2020-01-01",
                                  primary_creator_role: ["author", "artist", "photographer"],
                                  rights_granted: "Non-exclusive, North America, term-limited",
                                  rights_granted_creative_commons: "CC-BY",
                                  section_title: ["Chapter 2"],
                                  sort_date: "1997-01-11",
                                  transcript: "This is the transcript",
                                  translation: ["This is a translation"],
                                  use_crossref_xml: "no")}
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  before do
    monograph.ordered_members << cover
    monograph.save!
    cover.save!
    login_as user
    stub_out_redis
  end

  context "with solr_doc" do
    let(:doc) { SolrDocument.new(cover.to_solr) }
    scenario "On the file_set edit page" do
      visit edit_curation_concerns_file_set_path(cover.id)

      # These are assertions of what is, not neccessarily what is "right"

      expect(cover.allow_display_after_expiration).to eql 'lo-res'
      expect(doc.allow_display_after_expiration).to eql 'lo-res'
      expect(find('#file_set_allow_display_after_expiration')[:class]).to_not include 'multi-text-field'

      expect(cover.allow_download).to eql 'yes'
      expect(doc.allow_download).to eql 'yes'
      expect(find('#file_set_allow_download')[:class]).to_not include 'multi-text-field'

      expect(cover.allow_download_after_expiration).to eql 'no'
      expect(doc.allow_download_after_expiration).to eql 'no'
      expect(find('#file_set_allow_download_after_expiration')[:class]).to_not include 'multi-text-field'

      expect(cover.allow_hi_res).to eql 'yes'
      expect(doc.allow_hi_res).to eql 'yes'
      expect(find('#file_set_allow_hi_res')[:class]).to_not include 'multi-text-field'

      expect(cover.alt_text).to match_array(['This is the alt text'])
      expect(doc.alt_text).to match_array(['This is the alt text'])
      expect(find('#file_set_alt_text')[:class]).to_not include 'multi-text-field'

      expect(cover.book_needs_handles).to eql 'yes'
      expect(doc.book_needs_handles).to eql 'yes'
      expect(find('#file_set_book_needs_handles')[:class]).to_not include 'multi-text-field'

      expect(cover.caption).to match_array(['This is the caption'])
      expect(doc.caption).to match_array(['This is the caption'])
      expect(find('#file_set_caption')[:class]).to_not include 'multi-text-field'

      expect(cover.content_type).to match_array(['drawing', 'illustration'])
      expect(doc.content_type).to match_array(['drawing', 'illustration'])
      expect(find('#file_set_content_type')[:class]).to include 'multi-text-field'

      expect(cover.copyright_holder).to eql 'This is the © Copyright Holder'
      expect(doc.copyright_holder).to eql 'This is the © Copyright Holder'
      expect(find('#file_set_copyright_holder')[:class]).to_not include 'multi-text-field'

      expect(cover.copyright_status).to eql 'in-copyright'
      expect(doc.copyright_status).to eql 'in-copyright'
      expect(find('#file_set_copyright_status')[:class]).to_not include 'multi-text-field'

      expect(cover.credit_line).to eql 'Copyright by Some Person...'
      expect(doc.credit_line).to eql 'Copyright by Some Person...'
      expect(find('#file_set_credit_line')[:class]).to_not include 'multi-text-field'

      expect(cover.date_published).to match_array(["2017-01-01"])
      expect(doc.date_published).to match_array(["2017-01-01"])
      # Apparently we don't have date_published on the form? Seems like we should?
      expect(page).to_not have_selector '#file_set_date_published'

      expect(cover.display_date).to match_array(['circa. 2000'])
      expect(doc.display_date).to match_array(['circa. 2000'])
      expect(find('#file_set_display_date')[:class]).to include 'multi-text-field'

      expect(cover.doi).to eql ''
      expect(doc.doi).to eql ''
      expect(find('#file_set_doi')[:class]).to_not include 'multi-text-field'

      expect(cover.exclusive_to_platform).to eql 'yes'
      expect(doc.exclusive_to_platform).to eql 'yes'
      expect(find('#file_set_exclusive_to_platform')[:class]).to_not include 'multi-text-field'

      expect(cover.external_resource).to eql 'no'
      expect(doc.external_resource).to eql 'no'
      expect(find('#file_set_external_resource')[:class]).to_not include 'multi-text-field'

      expect(cover.ext_url_doi_or_handle).to eql 'Handle'
      expect(doc.ext_url_doi_or_handle).to eql 'Handle'
      expect(find('#file_set_ext_url_doi_or_handle')[:class]).to_not include 'multi-text-field'

      expect(cover.hdl).to eql ''
      expect(doc.hdl).to eql ''
      expect(find('#file_set_hdl')[:class]).to_not include 'multi-text-field'

      expect(cover.holding_contact).to eql 'Some museum or something somewhere'
      expect(doc.holding_contact).to eql 'Some museum or something somewhere'
      expect(find('#file_set_holding_contact')[:class]).to_not include 'multi-text-field'

      expect(cover.keywords).to match_array(["dogs", "cats", "fish"])
      expect(doc.keywords).to match_array(["dogs", "cats", "fish"])
      expect(find('#file_set_keywords')[:class]).to include 'multi-text-field'

      expect(cover.permissions_expiration_date).to eql '2020-01-01'
      expect(doc.permissions_expiration_date).to eql '2020-01-01'
      expect(find('#file_set_permissions_expiration_date')[:class]).to_not include 'multi-text-field'

      expect(cover.primary_creator_role).to match_array(["author", "artist", "photographer"])
      expect(doc.primary_creator_role).to match_array(["author", "artist", "photographer"])
      expect(find('#file_set_primary_creator_role')[:class]).to include 'multi-text-field'

      expect(cover.rights_granted).to eql 'Non-exclusive, North America, term-limited'
      expect(doc.rights_granted).to eql 'Non-exclusive, North America, term-limited'
      expect(find('#file_set_rights_granted')[:class]).to_not include 'multi-text-field'

      expect(cover.rights_granted_creative_commons).to eql 'CC-BY'
      expect(doc.rights_granted_creative_commons).to eql 'CC-BY'
      expect(find('#file_set_rights_granted_creative_commons')[:class]).to_not include 'multi-text-field'

      expect(cover.section_title).to match_array(["Chapter 2"])
      expect(doc.section_title).to match_array(["Chapter 2"])
      expect(find('#file_set_section_title')[:class]).to include 'multi-text-field'

      expect(cover.sort_date).to eql '1997-01-11'
      expect(doc.sort_date).to eql '1997-01-11'
      expect(find('#file_set_sort_date')[:class]).to_not include 'multi-text-field'

      expect(cover.transcript).to eql 'This is the transcript'
      expect(doc.transcript).to eql 'This is the transcript'
      expect(find('#file_set_transcript')[:class]).to_not include 'multi-text-field'

      expect(cover.translation).to match_array(["This is a translation"])
      expect(doc.translation).to eql 'This is a translation'
      expect(find('#file_set_translation')[:class]).to_not include 'multi-text-field'

      expect(cover.use_crossref_xml).to eql 'no'
      expect(doc.use_crossref_xml).to eql 'no'
      expect(find('#file_set_use_crossref_xml')[:class]).to_not include 'multi-text-field'
    end
  end
end
