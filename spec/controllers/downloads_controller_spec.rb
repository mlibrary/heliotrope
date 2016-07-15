require 'rails_helper'

describe DownloadsController do
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
        get :show, id: file_set
        expect(response.body).to eq file_set.original_file.content
      end
    end

    context "when allow_download is not yes" do
      let(:file_set) { create(:file_set,
                              user: user,
                              allow_download: 'no',
                              content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
      it "shows the unauthorized message" do
        get :show, id: file_set
        expect(response).to have_http_status(401)
      end
    end
  end
end
