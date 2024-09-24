# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreviousNextFileSetPresenter do


  describe "#previous_candidate_ids" do
    noids = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"]
    let(:monograph_presenter) { double("presenter", solr_document: {"ordered_member_ids_ssim" => noids}) }

    context "if in the middle" do
      it "returns the 5 noids before the file_set noid" do
        p = described_class.new(monograph_presenter, "g")
        expect(p.previous_candidate_ids).to eq ["b", "c", "d", "e", "f"]
      end
    end

    context "if close to the beginning" do
      it "returns previous noids" do
        p = described_class.new(monograph_presenter, "c")
        expect(p.previous_candidate_ids).to eq ["a", "b"]
      end
    end

    context "if the beginning" do
      it "returns an empty array" do
        p = described_class.new(monograph_presenter, "a")
        expect(p.previous_candidate_ids).to eq []
      end
    end
  end

  describe "next_candidate_ids" do
    noids = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"]
    let(:monograph_presenter) { double("presenter", solr_document: {"ordered_member_ids_ssim" => noids}) }

    context "if in the middle" do
      it "returns 5 noids after the file_set noid" do
        p = described_class.new(monograph_presenter, "g")
        expect(p.next_candidate_ids).to eq ["h", "i", "j", "k", "l"]
      end
    end

    context "if close to the end" do
      it "returns next noids" do
        p = described_class.new(monograph_presenter, "l")
        expect(p.next_candidate_ids).to eq ["m", "n"]
      end
    end

    context "if the end" do
      it "returns an empty array" do
        p = described_class.new(monograph_presenter, "n")
        expect(p.next_candidate_ids).to eq []
      end
    end
  end

end