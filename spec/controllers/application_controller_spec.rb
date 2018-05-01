# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController do
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

    # it "ActiveFedora::ActiveFedoraError with response unauthorized" do
    #   controller.the_exception = ActiveFedora::ActiveFedoraError.new
    #   get :trigger
    #   expect(response).to be_unauthorized
    # end

    it "ActiveRecord::RecordNotFound with response unauthorized" do
      controller.the_exception = ActiveRecord::RecordNotFound.new
      get :trigger
      expect(response).to be_unauthorized
    end
  end

  context 'institutions' do
    controller do
      def trigger; end
    end

    let(:keycard) { {} }
    let(:institution) { double('institution', identifier: 'identifier') }

    before do
      allow_any_instance_of(Keycard::RequestAttributes).to receive(:all).and_return(keycard)
      allow(Institution).to receive(:where).with(identifier: ['identifier']).and_return(institution)
      request.env["HTTP_ACCEPT"] = 'application/json'
      routes.draw { get "trigger" => "anonymous#trigger" }
      get :trigger
    end

    it { expect(controller.current_institutions?).to be false }
    it { expect(controller.current_institutions).to be_empty }

    context 'institution' do
      let(:keycard) { { "dlpsInstitutionId" => institution.identifier } }
      let(:institution) { double('institution', identifier: 'identifier') }

      it { expect(controller.current_institutions?).to be true }
      it { expect(controller.current_institutions).not_to be_empty }
      it { expect(controller.current_institutions.first).to be institution }
    end
  end
end
