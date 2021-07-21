# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  context 'rescue_from exception' do
    controller do
      attr_accessor :the_exception
      def trigger
        raise @the_exception
      end
    end

    before { routes.draw { get "trigger" => "anonymous#trigger" } }

    it "ActiveFedora::ObjectNotFoundError with response unauthorized" do
      controller.the_exception = ActiveFedora::ObjectNotFoundError.new
      get :trigger
      expect(response).to be_unauthorized
    end

    it "ActiveRecord::RecordNotFound with response unauthorized" do
      controller.the_exception = ActiveRecord::RecordNotFound.new
      get :trigger
      expect(response).to be_unauthorized
    end

    it "FileNotFoundError with response not found" do
      controller.the_exception = PageNotFoundError.new
      get :trigger
      expect(response).to be_not_found
    end
  end

  describe '#checkpoint_controller?' do
    it { expect(controller.send(:checkpoint_controller?)).to be false }
  end

  describe '#current_actor' do
    subject { controller.current_actor }

    let(:current_user) { }

    before { allow(controller).to receive(:current_user).and_return(current_user) }

    it { is_expected.to be_an_instance_of(Anonymous) }

    context 'Guest' do
      let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }

      it { is_expected.to be_an_instance_of(Guest) }
    end

    context 'User' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_an_instance_of(User) }
    end
  end

  context 'institution' do
    controller do
      def trigger; end
    end

    let(:institutions) { [] }

    before do
      allow(controller).to receive(:current_institutions).and_return(institutions)
      request.env["HTTP_ACCEPT"] = 'application/json'
      routes.draw { get "trigger" => "anonymous#trigger" }
      get :trigger
    end

    it { expect(controller.current_institutions?).to be false }
    it { expect(controller.current_institution).to be nil }
    it { expect(controller.current_institutions).to be institutions }

    context 'institution' do
      let(:institutions) { [institution] }
      let(:institution) { create(:institution) }

      it { expect(controller.current_institutions?).to be true }
      it { expect(controller.current_institution).to be institution }
    end

    context 'institutions' do
      let(:institutions) { [institution_05, institution_10, institution_2] }
      let(:institution_05) { create(:institution, identifier: "05") }
      let(:institution_10) { create(:institution, identifier: "10") }
      let(:institution_2) { create(:institution, identifier: "2") }

      it { expect(controller.current_institutions?).to be true }
      it { expect(controller.current_institution).to be institution_2 }
    end
  end

  context 'institutions' do
    controller do
      def trigger; end
    end

    let(:keycard) { {} }
    let(:institution) { create(:institution, identifier: dlps_institution_id.to_s, entity_id: 'https://entity.id') } # TODO: Prefix identifier value with '#'
    let(:institution_affiliation) { create(:institution_affiliation, institution: institution, dlps_institution_id: dlps_institution_id, affiliation: 'member') }
    let(:dlps_institution_id) { 9999 }

    before do
      institution_affiliation
      allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
      request.env["HTTP_ACCEPT"] = 'application/json'
      routes.draw { get "trigger" => "anonymous#trigger" }
      get :trigger
    end

    it { expect(controller.current_institutions?).to be false }
    it { expect(controller.current_institutions).to be_empty }

    context 'with an IP belonging to an institutional network' do
      let(:keycard) { { dlpsInstitutionId: [dlps_institution_id.to_s] } }

      it { expect(controller.current_institutions?).to be true }
      it { expect(controller.current_institutions).not_to be_empty }
      it { expect(controller.current_institutions.first).to eq institution }
    end

    context 'when authenticated via partner Shibboleth' do
      let(:keycard) { { identity_provider: 'https://entity.id' } }

      it { expect(controller.current_institutions?).to be true }
      it { expect(controller.current_institutions).not_to be_empty }
      it { expect(controller.current_institutions.first).to eq institution }
    end
  end
end
