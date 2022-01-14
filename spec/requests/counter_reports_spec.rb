# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Customers Counter Reports", type: :request do
  context "with the customer_id route" do
    let(:customer_id) { 'customer_id' }
    let(:platform_id) { 'platform_id' }

    context 'anonymous' do
      describe "GET /counter_reports/customers/:customer_id/platforms/:platform_id/reports" do
        it do
          expect { get counter_report_customer_platform_reports_path(customer_id: customer_id, platform_id: platform_id) }.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context 'user' do
      before { sign_in(current_user) }

      context 'unauthorized' do
        let(:current_user) { create(:user) }

        describe "GET /counter_reports/customers/:customer_id/platforms/:platform_id/reports" do
          it do
            expect { get counter_report_customer_platform_reports_path(customer_id: customer_id, platform_id: platform_id) }.to raise_error(ActionController::RoutingError)
          end
        end
      end

      context 'authorized' do
        let(:current_user) { create(:platform_admin) }
        let(:institution) { instance_double(Greensub::Institution, 'institution', id: customer_id, name: 'Institution') }
        let(:press) { instance_double(Press, 'press', id: platform_id, name: 'Press') }
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
          allow(Greensub::Institution).to receive(:find).with(customer_id).and_return(institution)
          allow(Press).to receive(:find).with(platform_id).and_return(press)
          allow(CounterReportService).to receive(:new).with(customer_id, platform_id, current_user).and_return(counter_report_service)
          allow(counter_report_service).to receive(:report).with('pr').and_return(counter_report)
          allow(counter_report).to receive(:report_header).and_return({})
          allow(counter_report).to receive(:report_items).and_return([])
        end

        describe "GET /counter_reports/customers/:customer_id/platforms/:platform_id/reports" do
          it do
            get counter_report_customer_platform_reports_path(customer_id: customer_id, platform_id: platform_id)
            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end

        describe "GET /counter_reports/customers/:customer_id/platforms/:platform_id/reports/:id/edit" do
          before do
            allow(Greensub::Institution).to receive(:find).with(customer_id).and_return(institution)
            allow(Press).to receive(:find).with(platform_id).and_return(press)
          end

          it do
            get edit_counter_report_customer_platform_report_path(customer_id: customer_id, platform_id: platform_id, id: 'pr')
            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:edit)
          end
        end

        describe "PUT /counter_reports/customers/:customer_id/platforms/:platform_id/reports/:id" do
          it do
            put counter_report_customer_platform_report_path(customer_id: customer_id, platform_id: platform_id, id: 'pr')
            expect(response).to have_http_status(:found)
            expect(response).to redirect_to counter_report_customer_platform_report_path(customer_id: customer_id, platform_id: platform_id, id: 'pr')
          end
        end

        describe "GET /counter_reports/customers/:customer_id/platforms/:platform_id/reports/:id" do
          it do
            get counter_report_customer_platform_report_path(customer_id: customer_id, platform_id: platform_id, id: 'pr')
            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:show)
          end
        end
      end
    end
  end

  # The whole idea of a "customer_id" (as well as requester_id) is related to
  # SUSHI and is apparently required to comply with the SUSHI standard.
  # We're not really sure what customer_ids or requesters are in the SUSHI context,
  # but we need people to be able to access COUNTER 5 reports right now.
  #
  # The /customers/:id/counter_reports routes are for supporting SUSHI requirements.
  # The /counter_reports routes don't require a customer_id. They are for accessing
  # COUNTER 5 reports in CSV (and in a web view) only, no SUSHI JSON.
  #
  # Someday, time permitting, maybe we'll figure out what SUSHI wants, then we
  # can consolidate everything.
  context "with no customer id" do
    let(:press) { create(:press) }

    context 'anonymous (no institutions)' do
      describe "GET /counter_reports" do
        it do
          get counter_reports_path
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "GET /counter_report/pr_1" do
        it do
          get counter_report_path(id: 'pr_p1')
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'known user with no institutions or presses' do
      let(:current_user) { create(:user) }

      describe "GET /counter_reports" do
        before { sign_in(current_user) }

        it do
          get counter_reports_path
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "GET /counter_report/pr_1" do
        it do
          get counter_report_path(id: 'pr_p1')
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'guest user with institutions' do
      let(:institutions) { [create(:institution, name: "blorf", identifier: 1), create(:institution, name: "ermoo", identifier: 2)] }

      before do
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a2', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        allow_any_instance_of(CounterReportsController).to receive(:current_institutions).and_return(institutions)
      end

      describe "GET /counter_reports" do
        it do
          get counter_reports_path
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end

      describe "GET /counter_report/pr_p1" do
        it do
          get counter_report_path(id: 'pr_p1'), params: { institution: 1, press: press.id }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      describe "GET /counter_report/pr" do
        it do
          get counter_report_path(id: 'pr'), params: { institution: 1, press: press.id, metric_types: ['Total_Item_Investigations'], data_types: ['Book'], access_types: ['Controlled'], access_methods: ['Regular'] }
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /counter_report/tr" do
        it do
          get counter_report_path(id: 'tr'), params: { institution: 1, press: press.id, metric_type: 'Unique_Title_Investigations', data_type: 'Book', access_type: 'OA_Gold', access_method: 'Regular' }
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /counter_report/tr_b1" do
        it do
          get counter_report_path(id: 'tr_b1'), params: { institution: 1, press: press.id }
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /counter_report/tr_b2" do
        it do
          get counter_report_path(id: 'tr_b2'), params: { institution: 1, press: press.id }
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /counter_reports/tr_b3" do
        it do
          get counter_report_path(id: 'tr_b3'), params: { institution: 1, press: press.id }
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /counter_reports/ir" do
        it do
          get counter_report_path(id: 'ir'), params: { institution: 1, press: press.id, metric_type: ['Total_Item_Requests', 'Unique_Item_Requests', 'Unique_Title_Requests'], data_type: 'Book', access_type: 'OA_Gold', access_method: 'Regular' }
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /counter_reports/ir_m1" do
        it do
          get counter_report_path(id: 'ir_m1'), params: { institution: 1, press: press.id }
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /counter_reports/counter4_br2" do
        it do
          get counter_report_path(id: 'counter4_br2'), params: { institution: 1, press: press.id }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'press admin user from no institution' do
      let(:current_user) { create(:press_admin) }
      let(:press_id) { current_user.roles.first.resource_id }
      let(:institutions) { [create(:institution, name: "blorf", identifier: 1), create(:institution, name: "ermoo", identifier: 2)] }

      before do
        create(:counter_report, press: press_id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
        create(:counter_report, press: press_id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press_id, session: 1,  noid: 'a2', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        # press admins have access to *all* institutions for their press only
        allow_any_instance_of(CounterReportsController).to receive(:current_institutions).and_return([])
        allow(Greensub::Institution).to receive(:order).and_return(institutions)
        allow(Greensub::Institution).to receive(:where).with(identifier: '1').and_return(institutions)
        sign_in(current_user)
      end

      describe "GET /counter_reports" do
        it do
          get counter_reports_path
          # HELIO-3526 press admins (and editors, analysts or other authed and prived users) will no longer
          # access reports through this controller, but instead through the dashboard and
          # hyrax/admin/stats_controller.rb
          expect(response).to have_http_status(:unauthorized)
          expect(response).not_to render_template(:index)
        end
      end

      describe "GET /counter_report/pr_p1" do
        context "the press admin's press" do
          it do
            get counter_report_path(id: 'pr_p1'), params: { institution: 1, press: press_id }
            # HELIO-3526
            expect(response).to have_http_status(:unauthorized)
            expect(response).not_to render_template(:show)
          end
        end

        context "a different press" do
          it do
            get counter_report_path(id: 'pr_p1'), params: { institution: 1, press: 1_000_000_000 }
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end
    end
  end
end
