# frozen_string_literal: true

class SubBrandsController < ApplicationController
  load_resource :press, find_by: :subdomain
  load_and_authorize_resource through: :press

  def show; end

  def new; end

  def create
    if @sub_brand.save
      redirect_to press_sub_brand_path(@press, @sub_brand)
    else
      render :new
    end
  end

  def edit; end

  def update
    if @sub_brand.update(sub_brand_params)
      redirect_to press_sub_brand_path(@press, @sub_brand)
    else
      render :edit
    end
  end

  private

    def sub_brand_params
      params.require(:sub_brand).permit(:title, :description)
    end
end
