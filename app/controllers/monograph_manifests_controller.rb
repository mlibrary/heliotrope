# frozen_string_literal: true

class MonographManifestsController < ApplicationController
  before_action :redirect_cancel, only: [:import]

  def export
    exporter = Export::Exporter.new(params[:id])
    send_data exporter.export.force_encoding("utf-8"), filename: "#{params[:id]}.csv"
  end

  def import
    @monograph_manifest = MonographManifest.new(params[:id])
    if @monograph_manifest.explicit.persisted?
      notice = t('monograph_manifests.notice.perform_job')
      UpdateMonographJob.perform_later(current_user, params[:id])
    else
      notice = t('monograph_manifests.notice.no_manifest')
    end
    redirect_to main_app.monograph_manifests_path, notice: notice
  end

  def preview
    @monograph_manifest = MonographManifest.new(params[:id])
    if @monograph_manifest.explicit.persisted?
      @presenter = MonographManifestPresenter.new(current_user, @monograph_manifest)
    else
      notice = t('monograph_manifests.notice.no_manifest')
      redirect_to main_app.monograph_manifests_path, notice: notice
    end
  end

  def show
    @presenter = MonographManifestPresenter.new(current_user, MonographManifest.new(params[:id]))
  end

  private
    def monograph_manifest_params
      params.require(:monograph_manifest).permit
    end

    def redirect_cancel
      redirect_to main_app.monograph_manifests_path(params[:id]) if params[:cancel]
    end
end
