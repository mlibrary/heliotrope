# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Customers Counter Reports", type: :request do
  let(:customer_id) { 'customer_id' }

  context 'anonymous' do
    describe "GET /customers/:customer_id/counter_reports" do
      it do
        expect { get customer_counter_reports_path(customer_id: customer_id) }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /customers/:customer_id/counter_reports" do
        it do
          expect { get customer_counter_reports_path(customer_id: customer_id) }.to raise_error(ActionController::RoutingError)
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
      let(:counter_report) { double('counter_report') }

      before do
        allow(CounterReportService).to receive(:new).with(customer_id, current_user.id).and_return(counter_report_service)
        allow(counter_report_service).to receive(:report).with('pr').and_return(counter_report)
        allow(counter_report).to receive(:report_header).and_return({})
        allow(counter_report).to receive(:report_items).and_return([])
      end

      describe "GET /customers/:customer_id/counter_reports" do
        it do
          get customer_counter_reports_path(customer_id: customer_id)
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end

      describe "GET /customers/:customer_id/counter_reports/:id/edit" do
        it do
          get edit_customer_counter_report_path(customer_id: customer_id, id: 'pr')
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:edit)
        end
      end

      describe "PUT /customers/:customer_id/counter_reports/:id" do
        it do
          put customer_counter_report_path(customer_id: customer_id, id: 'pr')
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to customer_counter_report_path(customer_id: customer_id, id: 'pr')
        end
      end

      describe "GET /customers/:customer_id/counter_reports/:id" do
        it do
          get customer_counter_report_path(customer_id: customer_id, id: 'pr')
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end
    end
  end
end
