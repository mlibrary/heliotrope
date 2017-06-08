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
                              rights
                              date_created
                              subject
                              language
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
                              date_published
                              isbn
                              isbn_paper
                              isbn_ebook
                              primary_editor_family_name
                              primary_editor_given_name
                              editor
                              copyright_holder
                              buy_url
                              sub_brand
                              creator_family_name
                              creator_given_name
                              section_titles] }
  end

  describe 'required_fields' do
    subject { described_class.required_fields }
    it { is_expected.to eq %i[title press creator_family_name creator_given_name description] }
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

  describe 'select_sub_brand' do
    subject { form.select_sub_brand }

    let!(:imprint) { create(:sub_brand, press: press1) }
    let!(:series) { create(:sub_brand, press: press1) }
    let!(:series2) { create(:sub_brand, press: press2) }
    let!(:another_press_sub_brand) { create(:sub_brand) }

    context 'a user who is a press-level admin' do
      before do
        create(:role, resource: press1, user: user, role: 'admin')
        create(:role, resource: press2, user: user, role: 'admin')
      end

      context 'when no press is selected' do
        let(:monograph) { Monograph.new }

        it 'contains sub-brands of presses I am an admin for' do
          expect(subject.count).to eq 3
          expect(subject[imprint.title]).to eq imprint.id
          expect(subject[series.title]).to eq series.id
          expect(subject[series2.title]).to eq series2.id

          expect(subject.key?(another_press_sub_brand.title)).to eq false
        end
      end

      context 'when a press is selected' do
        let(:monograph) { Monograph.new(press: press1.subdomain) }

        it 'only contains sub-brands of that press' do
          expect(subject.count).to eq 2
          expect(subject[imprint.title]).to eq imprint.id
          expect(subject[series.title]).to eq series.id

          expect(subject.key?(series2.title)).to eq false
          expect(subject.key?(another_press_sub_brand.title)).to eq false
        end
      end
    end
  end
end
