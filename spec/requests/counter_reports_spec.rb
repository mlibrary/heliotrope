# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Counter Reports", type: :request do
  let(:customer_id) { 'customer_id' }

  context 'anonymous' do
    describe "GET /counter_reports" do
      it do
        get counter_reports_path(customer_id: customer_id)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /counter_reports" do
        it do
          get counter_reports_path(customer_id: customer_id)
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }
      let(:counter_report_service) do
        instance_double(
          CounterReportService,
          'counter_report_service',
          description: 'description',
          note: 'note',
          alerts: [],
          active?: false
        )
      end

      before { allow(CounterReportService).to receive(:new).with(customer_id, current_user.id).and_return(counter_report_service) }

      describe "GET /counter_reports" do
        it do
          get counter_reports_path(customer_id: customer_id)
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end
    end
  end
end
