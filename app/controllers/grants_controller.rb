# frozen_string_literal: true

class GrantsController < ApplicationController
  before_action :set_grant, only: %i[show destroy]

  def index
    page = params.fetch("page", 1).to_i
    per_page = params.fetch("per_page", 20).to_i
    total_entries = Checkpoint::DB::Permit.count
    permits = Checkpoint::DB::Permit
    permits = permits.order { lower(agent_type) }.order_append(:agent_id)
    permits = permits.extension(:pagination).paginate(page, per_page, total_entries)
    @grants = Kaminari.paginate_array(permits.map { |permit| Grant.new(permit) }, total_count: total_entries).page(page).per(per_page)
  end

  def show; end

  def new
    @grant = Grant.new
  end

  def create # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    agent_type = grant_params[:agent_type]&.to_sym
    agent_id = grant_params[:agent_id] if grant_params[:agent_id].present?
    agent_id ||= (agent_type == :any) ? :any : grant_params["agent_#{agent_type.to_s.downcase}_id"]
    credential_type = grant_params[:credential_type]&.to_sym
    credential_id = grant_params[:credential_id] if grant_params[:credential_id].present?
    credential_id ||= (grant_params[:credential_id] == 'any') ? 'any' : grant_params["credential_#{credential_type.to_s.downcase}_id"]
    resource_type = grant_params[:resource_type]&.to_sym
    resource_id = grant_params[:resource_id] if grant_params[:resource_id].present?
    resource_id ||= (resource_type == :any) ? :any : grant_params["resource_#{resource_type.to_s.downcase}_id"]

    if resource_type == :Entity
      entity = Sighrax.factory(resource_id)
      resource_type = entity.type.to_sym
    end

    permit = if ValidationService.valid_credential?(credential_type, credential_id)
               case credential_type
               when :permission
                 case credential_id.to_s.to_sym
                 when :any
                   PermissionService.permit_any_access_resource(agent_type, agent_id, resource_type, resource_id)
                 when :read
                   PermissionService.permit_read_access_resource(agent_type, agent_id, resource_type, resource_id)
                 else
                   raise(ArgumentError)
                 end
               else
                 raise(ArgumentError)
               end
             end

    if permit.present?
      resource = PermissionService.resource(permit.resource_type, permit.resource_id)
      if resource.is_a?(Product)
        agent = PermissionService.agent(permit.agent_type, permit.agent_id)
        if agent.is_a?(Individual) || agent.is_a?(Institution)
          resource.lessees << agent.lessee unless resource.lessees.include?(agent.lessee) # rubocop:disable Metrics/BlockNesting
        end
      end
    else
      permit = Checkpoint::DB::Permit.new
      permit.agent_type = grant_params[:agent_type]
      permit.agent_id = grant_params[:agent_id]
      permit.agent_token = grant_params[:agent_token]
      permit.credential_type = grant_params[:credential_type]
      permit.credential_id = grant_params[:credential_id]
      permit.credential_token = grant_params[:credential_token]
      permit.resource_type = grant_params[:resource_type]
      permit.resource_id = grant_params[:resource_id]
      permit.resource_token = grant_params[:resource_token]
      permit.zone_id = grant_params[:zone_id]
    end

    @grant = Grant.new(permit)
    respond_to do |format|
      if @grant.valid?
        format.html { redirect_to @grant, notice: 'Grant was successfully created.' }
        format.json { render :show, status: :created, location: @grant }
      else
        format.html { render :new }
        format.json { render json: @grant.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    resource = PermissionService.resource(@grant.resource_type, @grant.resource_id)
    if resource.is_a?(Product)
      agent = PermissionService.agent(@grant.agent_type, @grant.agent_id)
      if agent.is_a?(Individual) || agent.is_a?(Institution)
        resource.lessees.delete(agent.lessee) if resource.lessees.include?(agent.lessee)
      end
    end
    @grant.destroy
    respond_to do |format|
      format.html { redirect_to grants_url, notice: 'Grant was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def set_grant
      permit = Checkpoint::DB::Permit.find(id: params[:id])
      @grant = Grant.new(permit) if permit.present?
    end

    def grant_params
      params.require(:grant).permit(
        :agent_type,
        :agent_id, :agent_guest_id, :agent_user_id, :agent_individual_id, :agent_institution_id,
        :credential_type,
        :credential_id, :credential_permission_id,
        :resource_type,
        :resource_id, :resource_entity_id, :resource_component_id, :resource_product_id
      )
    end
end
