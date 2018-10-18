# frozen_string_literal: true

class PoliciesController < ApplicationController
  before_action :set_policy, only: %i[show destroy]

  # GET /policies
  # GET /policies.json
  def index
    page = params.fetch("page", 1).to_i
    per_page = params.fetch("per_page", 20).to_i
    total_entries = params.fetch("total_entries", Policy.count / per_page + 1).to_i
    permits = Checkpoint::DB::Permit.dataset.extension(:pagination).paginate(page, per_page, total_entries)
    @policies = Kaminari.paginate_array(permits.map { |permit| Policy.new(permit) }, total_count: total_entries).page(page).per(per_page)
  end

  # GET /policies/1
  # GET /policies/1.json
  def show; end

  # GET /policies/new
  def new
    @policy = Policy.new
  end

  # POST /policies
  # POST /policies.json
  def create
    permit = begin
      PermissionService.new.permit_read_access_resource(policy_params[:agent_type].to_sym, policy_params[:agent_id], policy_params[:resource_type].to_sym, policy_params[:resource_id])
    rescue ArgumentError => _e
      nil
    end
    if permit.blank?
      permit = Checkpoint::DB::Permit.new
      permit.agent_type = policy_params[:agent_type]
      permit.agent_id = policy_params[:agent_id]
      permit.agent_token = policy_params[:agent_token]
      permit.credential_type = policy_params[:credential_type]
      permit.credential_id = policy_params[:credential_id]
      permit.credential_token = policy_params[:credential_token]
      permit.resource_type = policy_params[:resource_type]
      permit.resource_id = policy_params[:resource_id]
      permit.resource_token = policy_params[:resource_token]
      permit.zone_id = policy_params[:zone_id]
    end
    @policy = Policy.new(permit)
    respond_to do |format|
      if @policy.valid?
        format.html { redirect_to @policy, notice: 'Policy was successfully created.' }
        format.json { render :show, status: :created, location: @policy }
      else
        format.html { render :new }
        format.json { render json: @policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /policies/1
  # DELETE /policies/1.json
  def destroy
    @policy.destroy
    respond_to do |format|
      format.html { redirect_to policies_url, notice: 'Policy was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_policy
      permit = Checkpoint::DB::Permit.find(id: params[:id])
      @policy = Policy.new(permit) if permit.present?
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def policy_params
      params.require(:policy).permit(:agent_type, :agent_id, :agent_token, :credential_type, :credential_id, :credential_token, :resource_type, :resource_id, :resource_token, :zone_id)
    end
end
