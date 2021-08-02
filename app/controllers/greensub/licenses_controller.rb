# frozen_string_literal: true

module Greensub
  class LicensesController < ApplicationController
    before_action :set_license, only: %i[show edit update destroy]

    def index
      if params[:individual_id].present?
        @individual = Individual.find(params[:individual_id])
        @licenses = @individual.licenses.filter_by(filtering_params(params)).order(type: :asc).page(params[:page])
      elsif params[:institution_id].present?
        @institution = Institution.find(params[:institution_id])
        @licenses = @institution.licenses.filter_by(filtering_params(params)).order(type: :asc).page(params[:page])
      elsif params[:product_id].present?
        @product = Product.find(params[:product_id])
        @licenses = @product.licenses.filter_by(filtering_params(params)).order(type: :asc).page(params[:page])
      else
        @licenses = License.filter_by(filtering_params(params)).order(type: :asc).page(params[:page])
      end
    end

    def show; end

    def new
      @license = Greensub::License.new
    end

    def edit; end

    def create
      @license = License.new
      @license.type = license_params['type']
      @license.save
      respond_to do |format|
        if @license.save
          format.html { redirect_to @license, notice: 'License was successfully created.' }
          format.json { render :show, status: :created, location: @license }
        else
          format.html { render :new }
          format.json { render json: @license.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        valid = ValidationService.valid_license_type?(license_params['type'])
        if valid
          valid = @license.update(license_params)
        end
        if valid
          format.html { redirect_to greensub_licenses_path, notice: 'License was successfully updated.' }
          format.json { render :show, status: :ok, location: @license }
        else
          format.html { render :edit }
          format.json { render json: @license.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @license.destroy
      respond_to do |format|
        format.html { redirect_to greensub_licenses_url, notice: 'License was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

      def set_license
        @license = License.find(params[:id])
      end

      def license_params
        params.require(:greensub_license).permit(:type)
      end

      def filtering_params(params)
        params.slice(:type_like, :licensee_id_like, :product_id_like)
      end
  end
end
