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
                              contributor
                              description
                              license
                              rights_statement
                              publisher
                              date_created
                              subject
                              language
                              based_near
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
                              date_published
                              isbn
                              isbn_paper
                              isbn_ebook
                              hdl
                              doi
                              primary_editor_family_name
                              primary_editor_given_name
                              editor
                              copyright_holder
                              buy_url
                              creator_family_name
                              creator_given_name
                              section_titles] }
  end

  describe 'required_fields' do
    subject { described_class.required_fields }
    it { is_expected.to eq %i[title press creator_display creator_family_name creator_given_name description
                              publisher date_created] }
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
