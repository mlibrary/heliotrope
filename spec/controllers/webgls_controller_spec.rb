# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebglsController, type: :controller do
  after do
    FileUtils.rm_rf('./tmp/rspec_derivatives')
  end

  describe '#show' do
    context "when the file_set is a webgl" do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
      let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'webgl') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        UnpackJob.perform_now(file_set.id, 'webgl')
        allow(Webgl.logger).to receive(:info).and_return(nil)
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
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
      let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'webgl') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        UnpackJob.perform_now(file_set.id, 'webgl')
        allow(Webgl.logger).to receive(:info).and_return(nil)
      end

      after { FeaturedRepresentative.destroy_all }

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

      it "returns the loader file" do
        get :file, params: { id: file_set.id, file: 'Build/blah.loader', format: 'js' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be false
      end

      it "returns the data file" do
        get :file, params: { id: file_set.id, file: 'Build/blah', format: 'data' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be false
      end

      it "returns the framework file" do
        get :file, params: { id: file_set.id, file: 'Build/blah.framework', format: 'js' }
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be false
      end

      context "with a WASM file" do
        it "responds the file with correct type header for the file to be run as compiled code" do
          get :file, params: { id: file_set.id, file: 'Build/blah', format: 'wasm' }
          expect(response).to have_http_status(:success)
          expect(response.headers['Content-Type']).to eq('application/wasm')
        end
      end
    end
  end
end
