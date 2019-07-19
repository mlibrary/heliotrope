# frozen_string_literal: true

class FeaturedRepresentativesController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  def save
    fr = FeaturedRepresentative.where(monograph_id: params[:monograph_id],
                                      file_set_id: params[:file_set_id],
                                      kind: params[:kind]).first
    if fr.blank?
      FeaturedRepresentative.create!(monograph_id: params[:monograph_id],
                                     file_set_id: params[:file_set_id],
                                     kind: params[:kind])

      if ['epub', 'webgl', 'map'].include? params[:kind]
        UnpackJob.perform_later(params[:file_set_id], params[:kind])
      end
    end
    redirect_to monograph_show_path(params[:monograph_id])
  end

  def delete
    fr = FeaturedRepresentative.where(id: params[:id]).first
    fr.destroy if fr.present?
    redirect_to monograph_show_path(params[:monograph_id])
  end
end
