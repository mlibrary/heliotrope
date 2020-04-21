# frozen_string_literal: true

module Greensub
  class IndividualsController < ApplicationController
    before_action :set_individual, only: %i[show edit update destroy]

    def index
      if params[:product_id].present?
        @product = Product.find(params[:product_id])
        @individuals = Individual.where(id: @product.individuals.map(&:id)).filter(filtering_params(params)).order(identifier: :asc).page(params[:page])
      else
        @individuals = Individual.filter(filtering_params(params)).order(identifier: :asc).page(params[:page])
      end
    end

    def show; end

    def new
      @individual = Individual.new
    end

    def edit; end

    def create
      @individual = Individual.new(individual_params)
      respond_to do |format|
        if @individual.save
          format.html { redirect_to @individual, notice: 'Individual was successfully created.' }
          format.json { render :show, status: :created, location: @individual }
        else
          format.html { render :new }
          format.json { render json: @individual.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @individual.update(individual_params)
          format.html { redirect_to @individual, notice: 'Individual was successfully updated.' }
          format.json { render :show, status: :ok, location: @individual }
        else
          format.html { render :edit }
          format.json { render json: @individual.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @individual.destroy
      respond_to do |format|
        format.html { redirect_to greensub_individuals_url, notice: 'Individual was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

      def set_individual
        @individual = Individual.find(params[:id])
      end

      def individual_params
        params.require(:greensub_individual).permit(:identifier, :name, :email)
      end

      def filtering_params(params)
        params.slice(:identifier_like, :name_like, :email_like)
      end
  end
end
