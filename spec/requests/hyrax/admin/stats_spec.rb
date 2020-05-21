# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Hyrax Admin Stats", type: :request do
  context "a non-admin user" do
    let(:current_user) { create(:user) }

    describe "GET /admin/stats?partial=institution" do
      before { sign_in(current_user) }
      it "is unauthorized" do
        get hyrax.admin_stats_path(partial: 'institution')
        expect(response).to render_template('hyrax/base/unauthorized')
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context "a press admin" do
    let(:press) { create(:press, subdomain: "blue") }
    let(:press_admin) { create(:press_admin, press: press) }

    describe "GET /admin/stats?partial=institution" do
      before { sign_in(press_admin) }
      it "is authorized" do
        get hyrax.admin_stats_path(partial: 'institution')
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid email address" do
      describe "POST /admin/stats/institution" do
        before { sign_in(press_admin) }

        let(:params) { { email: "this is not a thing", press: "#{press.id}", start_date: "2019-01-01", end_date: "2019-12-31", report_type: "request" } }

        it "returns an error" do
          post "/admin/stats/institution", params: params
          expect(flash[:alert]).to be_present
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    describe "POST /admin/stats/institution" do
      before do
        sign_in(press_admin)
        allow(InstitutionReportJob).to receive(:perform_later).with({ args: params })
      end

      let(:params) { { email: press_admin.email, press: "#{press.id}", start_date: "2019-01-01", end_date: "2019-12-31", report_type: "request" } }

      it "runs the InstitutionReportJob" do
        post "/admin/stats/institution", params: params
        expect(flash[:notice]).to be_present
        expect(flash[:alert]).not_to be_present
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  context "a platform_admin" do
    let(:platform_admin) { create(:platform_admin) }

    describe "GET /admin/stats?partial=institution" do
      before { sign_in(platform_admin) }
      it "is authorized" do
        get hyrax.admin_stats_path(partial: 'institution')
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
