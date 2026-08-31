# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Jsapps", type: :request do
  context 'anonymous' do
    describe "GET /jsapps/#:id/file*" do
      let(:monograph) { create(:public_monograph) }
      let(:file_set) { create(:file_set) }
      let(:noid) { file_set.id }
      let(:filename) { 'file.txt' }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
      end

      it do
        get jsapp_file_path(noid, filename)
        expect(response).to have_http_status(:no_content)
      end

      context 'file.ext' do
        let(:filepath) { UnpackService.root_path_from_noid(noid, 'interactive_application') }

        before do
          FileUtils.mkdir_p(filepath)
          File.write(File.join(filepath, filename), 'jsapps')
        end

        after { FileUtils.rm_rf(filepath) }

        it do
          get jsapp_file_path(noid, filename)
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq('jsapps')
        end

        it 'prevents path traversal outside derivative directory' do
          get "/jsapps/#{noid}/../../../../config/database.yml"
          expect(response).to have_http_status(:no_content)
        end
      end

      context 'draft file set with a valid share link' do
        let(:monograph) { create(:monograph) }
        let(:valid_share_token) do
          JsonWebToken.encode(data: monograph.id, exp: Time.now.to_i + 28 * 24 * 3600)
        end
        let(:filepath) { UnpackService.root_path_from_noid(noid, 'interactive_application') }

        before do
          FileUtils.mkdir_p(filepath)
          File.write(File.join(filepath, filename), 'jsapps')
        end

        after { FileUtils.rm_rf(filepath) }

        it 'returns the file' do
          get jsapp_file_path(noid, filename), params: { share: valid_share_token }
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq('jsapps')
        end
      end
    end
  end
end
