# frozen_string_literal: true

require 'rails_helper'

describe ScoreIndexer do
  describe "#generate_solr_document" do
    subject { indexer.generate_solr_document }

    let(:indexer) { described_class.new(score) }
    let(:press) { create(:press, subdomain: Services.score_press, name: "Score Press") }
    let(:score) do
      build(:score,
            title: ['Test'],
            creator: ['Some Person'],
            press: press.subdomain)
    end
    let(:file_set) { create(:file_set) }

    before do
      score.ordered_members << file_set
      score.save!
    end

    it "indexes the ordered_members" do
      expect(subject['ordered_member_ids_ssim']).to eq [file_set.id]
    end

    context "when the ordered_members order changes" do
      let(:file_set2) { create(:file_set) }

      before do
        score.ordered_members = [file_set2, file_set]
        score.save!
      end

      it "has the indexed ordered_members in the right order" do
        expect(subject['ordered_member_ids_ssim']).to eq [file_set2.id, file_set.id]
      end
    end
  end
end
