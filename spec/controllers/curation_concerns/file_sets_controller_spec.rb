# frozen_string_literal: true

require 'rails_helper'

describe CurationConcerns::FileSetsController do
  let(:controller) { described_class.new }
  let(:params) { { file_set: { visibility_during_embargo: "restricted",
                               embargo_release_date: "2020-01-01",
                               visibility_after_embargo: "open",
                               visibility_during_lease: "open",
                               lease_expiration_date: "2020-01-01",
                               visibility_after_lease: "restricted" } } }

  describe "when visibility is embargo" do
    before do
      params[:file_set][:visibility] = 'embargo'
      controller.params = params
      controller.fix_visibility
    end
    it "has no visibility_during_lease" do
      expect(controller.params[:file_set][:visibility_during_lease]).to be nil
    end
    it "has a visibiltiy of restricted" do
      expect(controller.params[:file_set][:visibility]).to eq('restricted')
    end
  end

  describe "when visibiltiy is lease" do
    before do
      params[:file_set][:visibility] = 'lease'
      controller.params = params
      controller.fix_visibility
    end
    it "has no visibility_during_embargo" do
      expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
    end
    it "has a visibility of public" do
      expect(controller.params[:file_set][:visibility]).to eq('open')
    end
  end

  describe "when visibility is open" do
    before do
      params[:file_set][:visibility] = 'open'
      controller.params = params
      controller.fix_visibility
    end
    it "has no visibility_during_embargo" do
      expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
    end
    it "has no visibility_during_lease" do
      expect(controller.params[:file_set][:visibility_during_lease]).to be nil
    end
    it "has a visibility of public" do
      expect(controller.params[:file_set][:visibility]).to eq('open')
    end
  end

  describe "when visibility is private" do
    before do
      params[:file_set][:visibility] = 'restricted'
      controller.params = params
      controller.fix_visibility
    end
    it "has no visibility_during_embargo" do
      expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
    end
    it "has no visibility_during_lease" do
      expect(controller.params[:file_set][:visibility_during_lease]).to be nil
    end
    it "has a visibility of restricted" do
      expect(controller.params[:file_set][:visibility]).to eq('restricted')
    end
  end

  describe "when visibility is authenticated" do
    before do
      params[:file_set][:visibility] = 'authenticated'
      controller.params = params
      controller.fix_visibility
    end
    it "has no visibility_during_embargo" do
      expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
    end
    it "has no visibility_during_lease" do
      expect(controller.params[:file_set][:visibility_during_lease]).to be nil
    end
    it "has a visibility of authenticated" do
      expect(controller.params[:file_set][:visibility]).to eq('authenticated')
    end
  end
end
