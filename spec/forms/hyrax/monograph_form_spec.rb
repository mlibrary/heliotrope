# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::MonographForm do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:monograph) { Monograph.new }
  let(:form) { described_class.new(monograph, ability, Hyrax::MonographsController) }
  let(:press1) { create(:press) }
  let(:press2) { create(:press) }

  describe 'terms' do
    subject { described_class.terms }

    it {
      is_expected.to eq %i[title
                           description
                           creator
                           contributor
                           creator_display
                           publisher
                           date_created
                           subject
                           language
                           representative_id
                           thumbnail_id
                           rendering_ids
                           files
                           visibility_during_embargo
                           embargo_release_date
                           visibility_after_embargo
                           visibility_during_lease
                           lease_expiration_date
                           visibility_after_lease
                           visibility
                           ordered_member_ids
                           in_works_ids
                           member_of_collection_ids
                           admin_set_id
                           press
                           series
                           buy_url
                           isbn
                           doi
                           hdl
                           identifier
                           license
                           copyright_holder
                           open_access
                           funder
                           funder_display
                           holding_contact
                           location
                           section_titles
                           edition_name
                           previous_edition
                           next_edition
                           tombstone
                           tombstone_message
                           volume
                           oclc_owi
                           copyright_year]
    }
  end

  describe "#primary_terms" do
    subject { form.primary_terms }

    it {
      is_expected.to eq %i[title
                           press
                           creator
                           publisher
                           date_created
                           location]
    }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it {
      is_expected.to eq %i[description
                           contributor
                           creator_display
                           subject
                           language
                           series
                           buy_url
                           isbn
                           doi
                           hdl
                           identifier
                           license
                           copyright_holder
                           open_access
                           funder
                           funder_display
                           holding_contact
                           section_titles
                           edition_name
                           previous_edition
                           next_edition
                           tombstone
                           tombstone_message
                           volume
                           oclc_owi
                           copyright_year]
    }
  end

  describe 'required_fields' do
    subject { described_class.required_fields }

    it { is_expected.to eq %i[title press creator publisher date_created location] }
  end

  describe 'select_press' do
    subject { form.select_press }

    before do
      create(:role, resource: press1, user: user, role: 'admin')
      create(:role, resource: press2, user: user, role: 'editor')
    end

    it 'contains only the presses that I am an admin for' do
      expect(subject.count).to eq 1
      expect(subject[press1.name]).to eq press1.subdomain
    end
  end

  describe 'select_files' do
    subject { form.select_files }

    let(:file_set) { create(:file_set) }

    before do
      monograph.ordered_members << file_set
    end

    # Story #174
    it 'contains the file set' do
      expect(subject.count).to eq 1
    end
  end
end
