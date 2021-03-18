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
      entity = Sighrax.from_noid(resource_id)
      resource_type = entity.type.to_sym
    end

    success = if ValidationService.valid_credential_type?(credential_type)
                case credential_type
                when :License
                  license_grants = agent_resource_license_grants(agent_type, agent_id, resource_type, resource_id)
                  case license_grants.count
                  when 0
                    # new license
                    license = case credential_id.to_s.to_sym
                              when :full
                                Greensub::FullLicense.new
                              when :trial
                                Greensub::TrialLicense.new
                              else
                                raise(ArgumentError)
                              end
                    license.save
                    Authority.grant!(Authority.agent(agent_type, agent_id),
                                     Authority.credential(:License, license.id),
                                     Authority.resource(resource_type, resource_id))
                    true
                  when 1
                    # update license
                    grant = license_grants.first
                    license = Greensub::License.find(grant.credential_id.to_i)
                    license.type = case credential_id.to_s.to_sym
                                   when :full
                                     license.type = Greensub::FullLicense.to_s
                                   when :trial
                                     license.type = Greensub::TrialLicense.to_s
                                   else
                                     raise(ArgumentError)
                                   end
                    license.save
                    true
                  else
                    raise(ArgumentError)
                  end
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
              else
                false
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
    license = case @grant.credential_type
              when 'License'
                Greensub::License.find(@grant.credential_id)
              end
    @grant.delete
    license.destroy if license.present?
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
        :credential_id, :credential_license_id, :credential_permission_id,
        :resource_type,
        :resource_id, :resource_entity_id, :resource_component_id, :resource_product_id
      )
    end

    def agent_resource_license_grants(agent_type, agent_id, resource_type, resource_id)
      Checkpoint::DB::Grant
        .where(credential_type: 'License')
        .where(agent_type: agent_type.to_s, agent_id: agent_id.to_i, resource_type: resource_type.to_s, resource_id: resource_id.to_i)
    end
end
