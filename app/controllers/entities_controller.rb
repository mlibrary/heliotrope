# frozen_string_literal: true

class EntitiesController < ApplicationController
  before_action :set_entity, only: %i[show]

  # GET /entities
  # GET /entities.json
  def index
    @entities = [Entity.null_object]
  end

  # GET /entities/1
  # GET /entities/1.json
  def show; end

  # GET /entities/new
  # def new
  #   @entity = Entity.new
  # end

  # GET /entities/1/edit
  # def edit; end

  # POST /entities
  # POST /entities.json
  # def create
  #   @entity = Entity.new(entity_params)
  #   respond_to do |format|
  #     if @entity.save
  #       format.html { redirect_to @entity, notice: 'Entity was successfully created.' }
  #       format.json { render :show, status: :created, location: @entity }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @entity.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PATCH/PUT /entities/1
  # PATCH/PUT /entities/1.json
  # def update
  #   respond_to do |format|
  #     if @entity.update(entity_params)
  #       format.html { redirect_to @entity, notice: 'Entity was successfully updated.' }
  #       format.json { render :show, status: :ok, location: @entity }
  #     else
  #       format.html { render :edit }
  #       format.json { render json: @entity.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /entities/1
  # DELETE /entities/1.json
  # def destroy
  #   @entity.destroy
  #   respond_to do |format|
  #     format.html { redirect_to entities_url, notice: 'Entity was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_entity
      @entity = Entity.null_object
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def entity_params
      params.require(:entity).permit(:type, :id, :identifier, :name)
    end

    # A list of the param names that can be used for filtering the Product list
    def filtering_params(params)
      params.slice(:identifier_like, :name_like)
    end
end
