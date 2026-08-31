# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Jsapps", type: :request do
  context 'anonymous' do
    describe "GET /jsapps/#:id/file*" do
      let(:noid) { 'validnoid' }
      let(:filename) { 'file.txt' }

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
    end
  end
end
