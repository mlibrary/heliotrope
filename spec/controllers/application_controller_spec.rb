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
    before do
      routes.draw { get "trigger" => "anonymous#trigger" }
    end
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
end
