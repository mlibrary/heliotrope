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

      if ['epub', 'webgl', 'pdf_ebook'].include? params[:kind]
        UnpackJob.perform_later(params[:file_set_id], params[:kind])
      end
    end

    redirect_to monograph_show_path(params[:work_id])
  end

  def unpack
    fr = FeaturedRepresentative.where(file_set_id: params[:file_set_id]).first
    UnpackJob.perform_later(params[:file_set_id], fr.kind) if fr.present?
    redirect_to monograph_show_path(fr.work_id)
  end

  def delete
    fr = FeaturedRepresentative.where(file_set_id: params[:file_set_id]).first
    fr.destroy if fr.present?
    redirect_to monograph_show_path(params[:work_id])
  end
end
