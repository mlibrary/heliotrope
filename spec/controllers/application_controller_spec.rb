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

  context 'session' do
    controller do
      def trigger
        head :no_content
      end
    end

    before do
      routes.draw { get "trigger" => "anonymous#trigger" }
      get :trigger
    end

    it do
      expect(response).to have_http_status(:no_content)
    end
  end

  context 'empty' do
    let(:resource) { double('resource') }

    it 'works' do
      expect(subject.send(:clear_session_user)).to be nil
      expect(subject.send(:valid_user_signed_in?)).to be false
      # expect(subject.send(:user_sign_out_prompt)).to be false
      expect(subject.send(:user_sign_out)).to eq({})
      expect(subject.send(:store_user_location!)).to eq ""
      expect(subject.send(:storable_location?)).to be true
      expect(subject.send(:sign_in_static_cookie)).to be true
      expect(subject.send(:sign_out_static_cookie)).to be true
    end
  end
end
