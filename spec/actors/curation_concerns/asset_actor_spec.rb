require 'rails_helper'

describe CurationConcerns::Actors::AssetActor do
  let(:user) { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:actor) { described_class.new(file_set, user) }
  let(:work) { create(:monograph) }

  before do
    stub_out_redis
  end

  it "has the user's email address by default" do
    actor.create_metadata(work)
    expect(file_set.reload.creator).to eq([user.email])
  end

  # Story #188
  it "has the creator's name, not the user's email address" do
    actor.create_metadata(work, 'creator' => ["A Creator"])
    expect(file_set.reload.creator).to eq(["A Creator"])
  end
end
