# frozen_string_literal: true

class LesseesController < ApplicationController
  before_action :set_lessee, only: %i[show]

  def index
    @lessees = Lessee.filter(filtering_params(params)).order(identifier: :asc).page(params[:page])
  end

  def show; end

  private

    def set_lessee
      @lessee = Lessee.find(params[:id])
    end

    def filtering_params(params)
      params.slice(:identifier_like)
    end
end
