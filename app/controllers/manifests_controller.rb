# frozen_string_literal: true

class ManifestsController < ApplicationController
  before_action :redirect_cancel, only: %i[create update]

  def create
    csv = manifest_params[:csv] if params[:manifest].present?
    @manifest = Manifest.new(params[:id], csv)
    if csv.present?
      notice = "Error" unless @manifest.create(current_user)
      redirect_to monograph_manifests_path, notice: notice
    else
      flash[:notice] = "No file chosen"
      render :new
    end
  end

  def destroy
    @manifest = Manifest.new(params[:id])
    @manifest.destroy(current_user)
    redirect_to monograph_manifests_path
  end

  def edit
    @manifest = Manifest.new(params[:id])
    render
  end

  def new
    @manifest = Manifest.new(params[:id])
    render
  end

  def update
    csv = manifest_params[:csv] if params[:manifest].present?
    @manifest = Manifest.new(params[:id], csv)
    if csv.present?
      notice = "Error" unless @manifest.create(current_user)
      redirect_to monograph_manifests_path, notice: notice
    else
      flash[:notice] = "No file chosen"
      render :edit
    end
  end

  private

    def manifest_params
      params.require(:manifest).permit(:csv)
    end

    def redirect_cancel
      redirect_to main_app.monograph_manifests_path(params[:id]) if params[:cancel]
    end
end
