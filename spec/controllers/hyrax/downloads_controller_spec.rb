# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::DownloadsController, type: :controller do
  let(:user) { create(:user) }

  describe "#show" do
    context "when allow_download is yes" do
      let(:file_set) {
        create(:file_set,
               user: user,
               allow_download: 'yes',
               read_groups: ["public"],
               content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg')))
      }

      context "and a user is logged in" do
        before { sign_in user }

        it "sends the file" do
          get :show, params: { id: file_set.id, use_route: 'downloads' }
          expect(response.body).to eq file_set.original_file.content
        end
      end

      context "and the user is not logged in" do
        it "sends the file" do
          get :show, params: { id: file_set.id, use_route: 'downloads' }
          expect(response.body).to eq file_set.original_file.content
        end
      end
    end

    context "when allow_download is not yes" do
      let(:file_set) {
        create(:file_set,
               user: user,
               allow_download: 'no',
               read_groups: ["public"],
               content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg')))
      }

      context "and a non-edit user is logged in" do
        let(:non_edit_user) { create(:user) }

        before { sign_in non_edit_user }

        it "shows the unauthorized message" do
          get :show, params: { id: file_set.id, use_route: 'downloads' }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "and an edit user is logged in" do
        before { sign_in user }

        it "sends the file" do
          get :show, params: { id: file_set.id, use_route: 'downloads' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq file_set.original_file.content
        end
      end

      context "and the user is not logged in" do
        it "shows the unauthorized message" do
          get :show, params: { id: file_set.id, use_route: 'downloads' }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "and the user is logged in as a platform_admin" do
        let(:platform_admin) { create(:platform_admin) }

        before { sign_in platform_admin }

        it "sends the file" do
          get :show, params: { id: file_set.id, use_route: 'downloads' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq file_set.original_file.content
        end
      end
    end

    context "jpeg (for use as video poster attribute) derivative" do
      # allow_download is not relevant to derivative behavior
      let(:file_set) { create(:file_set, user: user, allow_download: 'no', read_groups: ['public']) }
      let(:thumbnail_path) { Hyrax::DerivativePath.derivative_path_for_reference(file_set.id, 'thumbnail') }
      # the new 'jpeg' derivative meant for video 'poster' attribute
      let(:jpeg_path) { Hyrax::DerivativePath.derivative_path_for_reference(file_set.id, 'jpeg') }
      let(:thumbnail_file) { File.join(fixture_path, 'csv', 'shipwreck.jpg') }
      let(:jpeg_file) { File.join(fixture_path, 'csv', 'miranda.jpg') }
      let(:derivatives_directory) { File.dirname(thumbnail_path) }

      before do
        FileUtils.mkdir_p(derivatives_directory)
      end

      it "if there is no jpeg derivative, it sends the thumbnail derivative in its stead" do
        # no derivatives for this FileSet yet
        expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 0

        # manually add a thumbnail derivative, check derivative count is 1
        FileUtils.cp(thumbnail_file, thumbnail_path)
        expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 1

        # ask for (missing) jpeg derivative, receive thumbnail instead
        get :show, params: { id: file_set.id, use_route: 'downloads', file: 'jpeg' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq IO.binread(thumbnail_file)
      end
      it "sends the jpeg derivative on request if it exists" do
        # no derivatives for this FileSet yet
        expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 0

        # manually add thumbnail and jpeg derivatives, check derivative count is 2
        FileUtils.cp(thumbnail_file, thumbnail_path)
        FileUtils.cp(jpeg_file, jpeg_path)
        expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 2

        # ask for, and receive, the jpeg derivative
        get :show, params: { id: file_set.id, use_route: 'downloads', file: 'jpeg' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq IO.binread(jpeg_file)
      end
      after do
        FileUtils.rm_rf(Hyrax.config.derivatives_path)
      end
    end

    context "PDF extracted_text download" do
      let(:file_set) {
        create(:file_set,
               user: user,
               allow_download: 'yes',
               read_groups: ["public"])
      }
      let(:text_file) do
        Hydra::PCDM::File.new.tap do |f|
          f.content = IO.read(File.join(fixture_path, 'test_pdf.txt'))
          f.original_name = 'test_pdf.txt'
          f.save!
        end
      end

      let(:mock_association) { double('blah') }

      before do
        allow(subject).to receive(:dereference_file).with(:extracted_text).and_return(mock_association)
      end

      context "When the extracted_text file exists" do
        before do
          allow(mock_association).to receive(:reader).and_return(text_file)
        end

        it "sends the file given the related URL parameter" do
          get :show, params: { id: file_set.id, file: 'extracted_text', use_route: 'downloads' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq IO.read(File.join(fixture_path, 'test_pdf.txt'))
        end
      end

      context "When the extracted_text file does not exist" do
        before do
          allow(mock_association).to receive(:reader).and_return(nil)
        end

        it "returns 401" do
          get :show, params: { id: file_set.id, file: 'extracted_text', use_route: 'downloads' }
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe "#mime_type_for" do
    let(:file) { File.join(fixture_path, 'it.mp4') }

    it "gives the correct mime_type for an mp4 video" do
      expect(subject.mime_type_for(file)).to eq('video/mp4')
    end
  end

  describe "allow_download is nil" do
    let(:file_set) {
      create(:file_set,
             user: user,
             content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg')))
    }

    it "does not raise an error when you try to download the file" do
      expect { get :show, params: { id: file_set.id, use_route: 'downloads' } }.not_to raise_error
    end
  end
end
