# frozen_string_literal: true

module Greensub
  class LicensesController < ApplicationController
    before_action :set_license, only: %i[show edit update type affiliations state destroy]

    def index
      if params[:individual_id].present?
        @individual = Individual.find(params[:individual_id])
        # @licenses = @individual.licenses.order(type: :asc).page(params[:page])
        @licenses = License.where(licensee_type: Greensub::Individual.to_s, licensee_id: params[:individual_id]).order(type: :asc).page(params[:page])
      elsif params[:institution_id].present?
        @institution = Institution.find(params[:institution_id])
        # @licenses = @institution.licenses.order(type: :asc).page(params[:page])
        @licenses = License.where(licensee_type: Greensub::Institution.to_s, licensee_id: params[:institution_id]).order(type: :asc).page(params[:page])
      elsif params[:product_id].present?
        @product = Product.find(params[:product_id])
        # @licenses = @product.licenses.order(type: :asc).page(params[:page])
        @licenses = License.where(product_id: params[:product_id]).filter_by(filtering_params(params)).order(type: :asc).page(params[:page])
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
      @license.licensee_type = license_params['licensee_type']
      @license.licensee_id = case @license.licensee_type
                             when Greensub::Individual.to_s
                               license_params['individual_id']
                             when Greensub::Institution.to_s
                               license_params['institution_id']
                             else
                               license_params['licensee_id']
                             end
      @license.product_id = license_params['product_id']
      saved = @license.save
      if saved

      end
      respond_to do |format|
        if saved
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

    def type
      respond_to do |format|
        valid = ValidationService.valid_license_type?(license_params['type'])
        if valid
          valid = @license.update(license_params)
        end
        if valid
          format.html { redirect_to greensub_license_path(@license), notice: 'License type was successfully updated.' }
          format.json { render :show, status: :ok, location: @license }
        else
          format.html { redirect_to greensub_license_path(@license), notice: 'License type was NOT successfully updated.' }
          format.json { render :show, status: :ok, location: @license }
        end
      end
    end

    def affiliations # rubocop:disable Metrics/PerceivedComplexity
      if @license.institution?
        if affiliations_params[:member].present?
          LicenseAffiliation.find_or_create_by(license: @license, affiliation: 'member')
        else
          LicenseAffiliation.find_by(license: @license, affiliation: 'member')&.destroy
        end
        if affiliations_params[:alum].present?
          LicenseAffiliation.find_or_create_by(license: @license, affiliation: 'alum')
        else
          LicenseAffiliation.find_by(license: @license, affiliation: 'alum')&.destroy
        end
        if affiliations_params[:walk_in].present?
          LicenseAffiliation.find_or_create_by(license: @license, affiliation: 'walk-in')
        else
          LicenseAffiliation.find_by(license: @license, affiliation: 'walk-in')&.destroy
        end
        respond_to do |format|
          format.html { redirect_to greensub_license_path(@license), notice: 'License affiliations were successfully updated.' }
          format.json { render :show, status: :ok, location: @license }
        end
      else
        respond_to do |format|
          format.html { redirect_to greensub_license_path(@license), notice: 'License affiliations were NOT successfully updated.' }
          format.json { render :show, status: :ok, location: @license }
        end
      end
    end

    def state
      if state_params[:active].present?
        unless @license.active?
          Authority.grant!(Authority.agent(@license.licensee.agent_type, @license.licensee.agent_id),
                           Authority.credential(@license.credential_type, @license.credential_id),
                           Authority.resource(@license.product.resource_type, @license.product.resource_id))
        end
      else
        if @license.active?
          grants = Checkpoint::DB::Grant.where(agent_type: @license.licensee.agent_type.to_s,
                                               agent_id: @license.licensee.agent_id.to_i,
                                               credential_type: @license.credential_type.to_s,
                                               credential_id: @license.credential_id.to_i,
                                               resource_type: @license.product.resource_type.to_s,
                                               resource_id: @license.product.resource_id.to_i)
          grants.first.delete
        end
      end
      respond_to do |format|
        format.html { redirect_to greensub_license_path(@license), notice: 'License state was successfully updated.' }
        format.json { render :show, status: :ok, location: @license }
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
        params.require(:greensub_license).permit(:type, :licensee_type, :individual_id, :institution_id, :licensee_id, :product_id)
      end

      def affiliations_params
        params.permit(:member, :alum, :walk_in)
      end

      def state_params
        params.permit(:active)
      end

      def filtering_params(params)
        # dup_params = params.dup
        if params[:institution_id_like].present?
          params[:licensee_type_like] = Greensub::Institution.to_s
          params[:licensee_id_like] = params[:institution_id_like]
        elsif params[:individual_id_like].present?
          params[:licensee_type_like] = Greensub::Individual.to_s
          params[:licensee_id_like] = params[:individual_id_like]
        else
          params[:licensee_type_like] = ""
          params[:licensee_id_like] = ""
        end
        params.slice(:type_like, :licensee_type_like, :licensee_id_like, :product_id_like)
      end
  end
end
