# frozen_string_literal: true

module Greensub
  class LicenseAffiliationsController < ApplicationController
    before_action :set_license_affiliation, only: %i[ show edit update destroy ]

    def index
      @license_affiliations = LicenseAffiliation.filter_by(filtering_params(params)).order(affiliation: :asc).page(params[:page])
    end

    def show
    end

    def new
      @license_affiliation = LicenseAffiliation.new
    end

    def edit
    end

    def create
      @license_affiliation = LicenseAffiliation.new(license_affiliation_params)
      respond_to do |format|
        if @license_affiliation.save
          format.html { redirect_to greensub_license_affiliation_path(@license_affiliation), notice: "License affiliation was successfully created." }
          format.json { render :show, status: :created, location: @license_affiliation }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @license_affiliation.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @license_affiliation.update(license_affiliation_params)
          format.html { redirect_to greensub_license_affiliation_path(@license_affiliation), notice: "License affiliation was successfully updated." }
          format.json { render :show, status: :ok, location: @license_affiliation }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @license_affiliation.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @license_affiliation.destroy
      respond_to do |format|
        format.html { redirect_to greensub_license_affiliations_url, notice: "License affiliation was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private

      def set_license_affiliation
        @license_affiliation = LicenseAffiliation.find(params[:id])
      end

      def license_affiliation_params
        params.require(:greensub_license_affiliation).permit(:license_id, :affiliation)
      end

      def filtering_params(params)
        params.slice(:license_id_like, :affiliation_like)
      end
  end
end
