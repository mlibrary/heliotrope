# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebglsController, type: :controller do
  after { Webgl::Cache.clear }

  describe '#show' do
    context "when the file_set is a webgl" do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.unity'))) }
      let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'webgl') }
      before do
        monograph.ordered_members << file_set
        monograph.save!
        get :show, params: { id: file_set.id }
      end
      after { FeaturedRepresentative.destroy_all }
      it { expect(response).to have_http_status(:success) }
    end

    context "when the file_set is not a webgl" do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      before { get :show, params: { id: file_set.id } }
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe '#file' do
    context "the file_set is a webgl" do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.unity'))) }
      let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'webgl') }
      before do
        monograph.ordered_members << file_set
        monograph.save!
      end
      after { FeaturedRepresentative.destroy_all }
      it "returns the UnityLoader.js file" do
        get :file, params: { id: file_set.id, file: 'Build/UnityLoader', format: 'js' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be false
      end

      it "does not return a nonexistent file" do
        get :file, params: { id: file_set.id, file: 'Build/NotAThing', format: 'js' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end

      it "does not return /etc/passwd :)" do
        get :file, params: { id: file_set.id, file: '/etc/passwd', format: '' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end

      context "without an Accept-Encoding gzip header" do
        it "returns an uncompressed file" do
          get :file, params: { id: file_set.id, file: 'Build/thing.asm.memory', format: 'unityweb' }
          expect(response).to have_http_status(:success)
          expect(response.body).to eq "var things = \"things\";\n"
        end
      end

      context "with an Accept-Encoding gzip header" do
        let(:header) { { 'Accept-Encoding' => 'gzip, deflate, br' } }
        it "returns a compressed file" do
          request.headers.merge! header
          get :file, params: { id: file_set.id, file: 'Build/thing.asm.memory', format: 'unityweb' }
          expect(response).to have_http_status(:success)
          expect(response.body).to eq "\u001F\x8B\b\bT\xAB\xA2Z\u0000\u0003thing.asm.memory.unityweb\u0000+K,R(\xC9\xC8\xCCK/V\xB0UP\x82\xB0\x94\xAC\xB9\u0000\xD4\xDB\xCD\xFC\u0017\u0000\u0000\u0000"
        end
      end
    end
  end
end
