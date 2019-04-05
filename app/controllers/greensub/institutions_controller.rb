# frozen_string_literal: true

module Greensub
  class InstitutionsController < ApplicationController
    before_action :set_institution, only: %i[show edit update destroy login help]

    def index
      @institutions = Institution.filter(filtering_params(params)).order(identifier: :asc).page(params[:page])
    end

    def show; end

    def new
      @institution = Institution.new
    end

    def edit; end

    def create
      @institution = Institution.new(institution_params)
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
        params.require(:greensub_institution).permit(:identifier, :name, :entity_id, :site, :login)
      end

      def filtering_params(params)
        params.slice(:identifier_like, :name_like, :entity_id_like)
      end
  end
end
