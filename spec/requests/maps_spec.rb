# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Maps", type: :request do
  context 'anonymous' do
    describe "GET /maps/#:id/file*" do
      let(:noid) { 'validnoid' }
      let(:filename) { 'file.txt' }

      it do
        get map_file_path(noid, filename)
        expect(response).to have_http_status(:no_content)
      end

      context 'file.ext' do
        let(:filepath) { UnpackService.root_path_from_noid(noid, 'map') }

        before do
          FileUtils.mkdir_p(filepath)
          File.write(File.join(filepath, filename), 'maps')
        end

        after { FileUtils.rm_rf(filepath) }

        it do
          get map_file_path(noid, filename)
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq('maps')
        end
      end
    end
  end
end
