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
                            :date_published,
                            :isbn,
                            :editor,
                            :copyright_holder,
                            :buy_url] }
  end
end
