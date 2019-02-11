# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::Forms::BatchUploadForm do
  let(:user) { create(:user) }
  let(:controller) { instance_double(Hyrax::BatchUploadsController) }
  let(:monograph) { Monograph.new }
  let(:ability) { Ability.new(user) }
  let(:form) { described_class.new(monograph, ability, controller) }

  let(:press1) { create(:press) }
  let(:press2) { create(:press) }

  describe 'terms' do
    subject { form.terms }

    it {
      is_expected.to eq %i[creator
                           contributor
                           description
                           keyword
                           license
                           rights_statement
                           publisher
                           date_created
                           subject
                           language
                           identifier
                           based_near
                           related_url
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
                           source
                           in_works_ids
                           member_of_collection_ids
                           admin_set_id
                           press]
    }
  end

  describe "#primary_terms" do
    subject { form.primary_terms }

    it { is_expected.to eq [:press] }
    it { is_expected.not_to include(:title) }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it { is_expected.not_to include(:title) } # title is per file, not per form
  end

  describe 'required_fields' do
    subject { form.required_fields }

    it { is_expected.to eq %i[press] }
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
