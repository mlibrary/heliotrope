# frozen_string_literal: true

class GrantsController < ApplicationController
  before_action :set_grant, only: %i[show destroy]

  def index
    @grants = Checkpoint::DB::Grant.all
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

    success = if ValidationService.valid_credential?(credential_type, credential_id)
                case credential_type
                when :permission
                  case credential_id.to_s.to_sym
                  when :any
                    unless Authority.permits?(Authority.agent(agent_type, agent_id), Checkpoint::Credential::Permission.new(:any), Authority.resource(resource_type, resource_id)) # rubocop:disable Metrics/BlockNesting
                      Authority.grant!(Authority.agent(agent_type, agent_id), Checkpoint::Credential::Permission.new(:any), Authority.resource(resource_type, resource_id))
                    end
                    true
                  when :read
                    unless Authority.permits?(Authority.agent(agent_type, agent_id), Checkpoint::Credential::Permission.new(:read), Authority.resource(resource_type, resource_id)) # rubocop:disable Metrics/BlockNesting
                      Authority.grant!(Authority.agent(agent_type, agent_id), Checkpoint::Credential::Permission.new(:read), Authority.resource(resource_type, resource_id))
                    end
                    true
                  else
                    raise(ArgumentError)
                  end
                else
                  raise(ArgumentError)
                end
              end

    if success
      resource = Authority.resource(resource_type, resource_id)
      if resource.is_a?(Product)
        agent = Authority.agent(agent_type, agent_id)
        if agent.is_a?(Individual) || agent.is_a?(Institution)
          resource.lessees << agent.lessee unless resource.lessees.include?(agent.lessee) # rubocop:disable Metrics/BlockNesting
        end
      end
    end

    @grant = Grant.new
    @grant.agent_type = grant_params[:agent_type]
    @grant.agent_id = grant_params[:agent_id]
    @grant.credential_type = grant_params[:credential_type]
    @grant.credential_id = grant_params[:credential_id]
    @grant.resource_type = grant_params[:resource_type]
    @grant.resource_id = grant_params[:resource_id]

    respond_to do |format|
      if success
        format.html { redirect_to grants_path, notice: 'Grant was successfully created.' }
        format.json { render :show, status: :created, location: @grant }
      else
        format.html { render :new }
        format.json { render json: @grant.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    resource = Authority.resource(@grant.resource_type, @grant.resource_id)
    if resource.is_a?(Product)
      agent = Authority.agent(@grant.agent_type, @grant.agent_id)
      if agent.is_a?(Individual) || agent.is_a?(Institution)
        resource.lessees.delete(agent.lessee) if resource.lessees.include?(agent.lessee)
      end
    end
    @grant.delete
    respond_to do |format|
      format.html { redirect_to grants_url, notice: 'Grant was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def set_grant
      @grant = Checkpoint::DB::Grant.where(id: params[:id]).first
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
