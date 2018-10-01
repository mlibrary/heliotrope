# frozen_string_literal: true

class PoliciesController < ApplicationController
  before_action :set_policy, only: %i[show edit update destroy]

  # GET /policies
  # GET /policies.json
  def index
    page = params.fetch("page", 1).to_i
    per_page = params.fetch("per_page", 20).to_i
    total_entries = params.fetch("total_entries", Policy.count / per_page + 1).to_i
    permits = Checkpoint::DB::Permit.dataset.extension(:pagination).paginate(page, per_page, total_entries)
    @policies = permits.map { |permit| Policy.new(permit) }.paginate(page: page, per_page: per_page, total_entries: total_entries)
  end

  # GET /policies/1
  # GET /policies/1.json
  def show; end

  # GET /policies/new
  def new
    @policy = Policy.new
  end

  # GET /policies/1/edit
  def edit; end

  # POST /policies
  # POST /policies.json
  # POST /products/product_id:/policies
  def create # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      permit = Checkpoint::DB::Permit.find(id: params[:id])
      @policy = Policy.new(permit) if permit.present?
      if product.present? && @policy.present? && !product.policies.include?(@policy)
        product.policies << @policy
      end
      redirect_to product
    else
      @policy = Policy.new
      @policy.set(policy_params.to_hash)
      @policy.save if @policy.valid?
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
  end

  # PATCH/PUT /policies/1
  # PATCH/PUT /policies/1.json
  def update
    respond_to do |format|
      if @policy.update(policy_params.to_hash)
        format.html { redirect_to @policy, notice: 'Policy was successfully updated.' }
        format.json { render :show, status: :ok, location: @policy }
      else
        format.html { render :edit }
        format.json { render json: @policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /policies/1
  # DELETE /policies/1.json
  # DELETE /products/product_id:/policies/:id
  def destroy
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      if product.present? && @policy.present? && product.policies.include?(@policy)
        product.policies.delete(@policy)
      end
      redirect_to product
    else
      @policy.destroy
      respond_to do |format|
        format.html { redirect_to policies_url, notice: 'Policy was successfully destroyed.' }
        format.json { head :no_content }
      end
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
