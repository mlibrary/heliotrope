# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DownloadsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "#show" do
    context "when allow_download is yes" do
      let(:file_set) { create(:file_set,
                              user: user,
                              allow_download: 'yes',
                              content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }

      it "sends the file" do
        get :show, params: { id: file_set.id, use_route: 'downloads' }
        expect(response.body).to eq file_set.original_file.content
      end
    end

    context "when allow_download is not yes" do
      let(:file_set) { create(:file_set,
                              user: user,
                              allow_download: 'no',
                              content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }

      it "shows the unauthorized message" do
        get :show, params: { id: file_set.id, use_route: 'downloads' }
        expect(response).to have_http_status(401)
      end
    end
  end

  describe "#mime_type_for" do
    let(:file) { File.join(fixture_path, 'it.mp4') }

    it "gives the correct mime_type for an mp4 video" do
      expect(subject.mime_type_for(file)).to eq('video/mp4')
    end
  end
end
