# frozen_string_literal: true

module Greensub
  class InstitutionsController < ApplicationController
    before_action :set_institution, only: %i[show edit update destroy login help]

    def index
      if params[:product_id].present?
        @product = Product.find(params[:product_id])
        @institutions = Institution.where(id: @product.institutions.map(&:id)).filter_by(filtering_params(params)).order(identifier: :asc).page(params[:page])
      else
        @institutions = Institution.filter_by(filtering_params(params)).order(identifier: :asc).page(params[:page])
      end
    end

    def show; end

    def new
      @institution = Institution.new
    end

    def edit; end

    def create
      @institution = Institution.new(institution_params)
      @institution.display_name = @institution.name if @institution.display_name.blank?
      respond_to do |format|
        if @institution.save
          format.html { redirect_to greensub_institution_path(@institution), notice: 'Institution was successfully created.' }
          format.json { render :show, status: :created, location: @institution }
        else
          format.html { render :new }
          format.json { render json: @institution.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @institution.update(institution_params)
          format.html { redirect_to greensub_institution_path(@institution), notice: 'Institution was successfully updated.' }
          format.json { render :show, status: :ok, location: @institution }
        else
          format.html { render :edit }
          format.json { render json: @institution.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @institution.destroy
      respond_to do |format|
        format.html { redirect_to greensub_institutions_url, notice: 'Institution was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

      def set_institution
        @institution = Institution.find(params[:id])
      end

      def institution_params
        params.require(:greensub_institution).permit(:identifier, :name, :display_name, :entity_id, :catalog_url, :link_resolver_url, :location, :login, :logo_path, :ror_id, :site)
      end

      def filtering_params(params)
        params.slice(:identifier_like, :name_like, :display_name_like, :entity_id_like)
      end
  end
end
