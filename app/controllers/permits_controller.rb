# frozen_string_literal: true

require 'will_paginate'
require 'will_paginate/sequel'
require 'will_paginate/collection'
require 'will_paginate/version'
require 'sequel/extensions/pagination'

class PermitsController < ApplicationController
  before_action :set_permit, only: %i[show edit update destroy]

  # GET /permits
  # GET /permits.json
  def index
    page = params.fetch "page", 1
    per_page = params.fetch "per_page", 20
    @permits = Permit.dataset.extension(:pagination).paginate(page.to_i, per_page.to_i)
  end

  # GET /permits/1
  # GET /permits/1.json
  def show; end

  # GET /permits/new
  def new
    @permit = Permit.new
  end

  # GET /permits/1/edit
  def edit; end

  # POST /permits
  # POST /permits.json
  def create
    @permit = Permit.new
    @permit.set(permit_params.to_hash)
    respond_to do |format|
      if @permit.save
        format.html { redirect_to @permit, notice: 'Permit was successfully created.' }
        format.json { render :show, status: :created, location: @permit }
      else
        format.html { render :new }
        format.json { render json: @permit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /permits/1
  # PATCH/PUT /permits/1.json
  def update
    respond_to do |format|
      if @permit.update(permit_params.to_hash)
        format.html { redirect_to @permit, notice: 'Permit was successfully updated.' }
        format.json { render :show, status: :ok, location: @permit }
      else
        format.html { render :edit }
        format.json { render json: @permit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /permits/1
  # DELETE /permits/1.json
  def destroy
    @permit.destroy
    respond_to do |format|
      format.html { redirect_to permits_url, notice: 'Permit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_permit
      @permit = Permit.find(id: params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def permit_params
      params.require(:permit).permit(:agent_type, :agent_id, :agent_token, :credential_type, :credential_id, :credential_token, :resource_type, :resource_id, :resource_token, :zone_id)
    end
end
