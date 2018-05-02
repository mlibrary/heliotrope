# frozen_string_literal: true

class GroupingsController < ApplicationController
  before_action :set_grouping, only: %i[show edit update destroy]

  # GET /groupings
  # GET /groupings.json
  def index
    @groupings = Grouping.all
  end

  # GET /groupings/1
  # GET /groupings/1.json
  def show; end

  # GET /groupings/new
  def new
    @grouping = Grouping.new
  end

  # GET /groupings/1/edit
  def edit; end

  # POST /groupings
  # POST /groupings.json
  def create # rubocop:disable Metrics/PerceivedComplexity
    if params[:lessee_id].present?
      lessee = Lessee.find(params[:lessee_id])
      @grouping = Grouping.find(params[:id])
      if @grouping.present? && lessee.present? && !@grouping.lessees.include?(lessee)
        @grouping.lessees << lessee
      end
      redirect_to lessee
    else
      @grouping = Grouping.new(grouping_params)
      respond_to do |format|
        if @grouping.save
          format.html { redirect_to @grouping, notice: 'Grouping was successfully created.' }
          format.json { render :show, status: :created, location: @grouping }
        else
          format.html { render :new }
          format.json { render json: @grouping.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /groupings/1
  # PATCH/PUT /groupings/1.json
  def update
    respond_to do |format|
      if @grouping.update(grouping_params)
        format.html { redirect_to @grouping, notice: 'Grouping was successfully updated.' }
        format.json { render :show, status: :ok, location: @grouping }
      else
        format.html { render :edit }
        format.json { render json: @grouping.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groupings/1
  # DELETE /groupings/1.json
  def destroy
    if params[:lessee_id].present?
      lessee = Lessee.find(params[:lessee_id])
      @grouping = Grouping.find(params[:id])
      if @grouping.present? && lessee.present? && @grouping.lessees.include?(lessee)
        @grouping.lessees.delete(lessee)
      end
      redirect_to lessee
    else
      @grouping.destroy
      respond_to do |format|
        format.html { redirect_to groupings_url, notice: 'Grouping was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_grouping
      @grouping = Grouping.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def grouping_params
      params.require(:grouping).permit(:identifier)
    end
end
