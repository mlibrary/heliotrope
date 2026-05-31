# frozen_string_literal: true
module ActiveEncode
  class EncodeRecordController < ActionController::Base
    rescue_from ActiveRecord::RecordNotFound do |e|
      render json: { message: e.message }, status: :not_found
    end

    def show
      @encode_record = ActiveEncode::EncodeRecord.find(params[:id])
      render json: @encode_record.raw_object, status: :ok
    end
  end
end
