require 'rails_helper'

describe CurationConcerns::MonographForm do
  describe 'terms' do
    subject { described_class.terms }
    it { is_expected.to eq [:title,
                            :creator,
                            :contributor,
                            :description,
                            :tag,
                            :rights,
                            :publisher,
                            :date_created,
                            :subject,
                            :language,
                            :identifier,
                            :based_near,
                            :related_url,
                            :representative_id,
                            :thumbnail_id,
                            :files,
                            :visibility_during_embargo,
                            :embargo_release_date,
                            :visibility_after_embargo,
                            :visibility_during_lease,
                            :lease_expiration_date,
                            :visibility_after_lease,
                            :visibility,
                            :ordered_member_ids,
                            :press,
                            :date_published,
                            :isbn,
                            :editor,
                            :copyright_holder,
                            :buy_url] }
  end

  describe 'required_fields' do
    subject { described_class.required_fields }
    it { is_expected.to eq [:title, :press] }
  end

  describe 'select_press' do
    let(:user) { create(:user) }
    let(:ability) { Ability.new(user) }
    let(:press1) { create(:press) }
    let(:press2) { create(:press) }
    let(:form) { described_class.new(Monograph.new, ability) }

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
end
