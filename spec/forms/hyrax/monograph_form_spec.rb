# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::MonographForm do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:form) { described_class.new(monograph, ability, Hyrax::MonographsController) }

  let(:press1) { create(:press) }
  let(:press2) { create(:press) }

  describe 'terms' do
    subject { described_class.terms }
    it { is_expected.to eq %i[title
                              creator
                              contributor
                              description
                              publisher
                              date_created
                              subject
                              language
                              identifier
                              representative_id
                              thumbnail_id
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
                              creator_display
                              isbn
                              doi
                              hdl
                              copyright_holder
                              holding_contact
                              buy_url
                              section_titles
                              location
                              series] }
  end

  describe 'required_fields' do
    subject { described_class.required_fields }
    it { is_expected.to eq %i[title press description creator publisher date_created location] }
  end

  describe 'select_press' do
    subject { form.select_press }
    let(:monograph) { Monograph.new }

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
    let(:monograph) { Monograph.new }
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
