# frozen_string_literal: true

class FeaturedRepresentativesController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  def save
    fr = FeaturedRepresentative.where(work_id: params[:work_id],
                                      file_set_id: params[:file_set_id],
                                      kind: params[:kind]).first
    if fr.blank?
      FeaturedRepresentative.create!(work_id: params[:work_id],
                                     file_set_id: params[:file_set_id],
                                     kind: params[:kind])

      if ['epub', 'webgl'].include? params[:kind]
        UnpackJob.perform_later(params[:file_set_id], params[:kind])
      end
    end

    if Sighrax.factory(params[:work_id]).is_a?(Sighrax::Score)
      redirect_to score_show_path(params[:work_id])
    else
      redirect_to monograph_catalog_path(params[:work_id])
    end
  end

  def delete
    fr = FeaturedRepresentative.where(id: params[:file_set_id]).first
    fr.destroy if fr.present?
    if Sighrax.factory(params[:work_id]).is_a?(Sighrax::Score)
      redirect_to score_show_path(params[:work_id])
    else
      redirect_to monograph_catalog_path(params[:work_id])
    end
  end
end
