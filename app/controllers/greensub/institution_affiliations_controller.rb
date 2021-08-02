# frozen_string_literal: true

module Greensub
  class InstitutionAffiliationsController < ApplicationController
    before_action :set_institution_affiliation, only: %i[ show edit update destroy ]

    def index
      if params[:institution_id].present?
        @institution = Institution.find(params[:institution_id])
        @institution_affiliations = @institution.institution_affiliations.filter_by(filtering_params(params)).order(dlps_institution_id: :asc).page(params[:page])
      else
        @institution_affiliations = InstitutionAffiliation.filter_by(filtering_params(params)).order(dlps_institution_id: :asc).page(params[:page])
      end
    end

    def show
    end

    def new
      @institution_affiliation = InstitutionAffiliation.new
    end

    def edit
    end

    def create
      @institution_affiliation = InstitutionAffiliation.new(institution_affiliation_params)
      respond_to do |format|
        if @institution_affiliation.save
          format.html { redirect_to greensub_institution_affiliation_path(@institution_affiliation), notice: "Institution affiliation was successfully created." }
          format.json { render :show, status: :created, location: @institution_affiliation }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @institution_affiliation.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @institution_affiliation.update(institution_affiliation_params)
          format.html { redirect_to greensub_institution_affiliation_path(@institution_affiliation), notice: "Institution affiliation was successfully updated." }
          format.json { render :show, status: :ok, location: @institution_affiliation }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @institution_affiliation.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @institution_affiliation.destroy
      respond_to do |format|
        format.html { redirect_to greensub_institution_affiliations_url, notice: "Institution affiliation was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private

      def set_institution_affiliation
        @institution_affiliation = InstitutionAffiliation.find(params[:id])
      end

      def institution_affiliation_params
        params.require(:greensub_institution_affiliation).permit(:institution_id, :dlps_institution_id, :affiliation)
      end

      def filtering_params(params)
        params.slice(:institution_id_like, :dlps_institution_id_like, :affiliation_like)
      end
  end
end
