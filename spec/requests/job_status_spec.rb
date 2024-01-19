# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "JobStatus", type: :request do
  let(:press) { create(:press) }
  describe 'GET /job_status/:id' do
    let(:status) { create(:job_status) }

    it do
      get job_status_path(status.id), params: { press_id: press.id, download_redirect: 'some_url' }
      expect(response).to have_http_status(:ok)
    end
  end
end
