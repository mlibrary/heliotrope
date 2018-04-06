# frozen_string_literal: true

module API
  module V1
    class LesseesController < API::ApplicationController
      respond_to :json
      before_action :set_lessee, only: %i[show update destroy]

      def index
        @lessees = []
        if params[:product_identifier].present?
          product = Product.find_or_create_by!(identifier: params[:product_identifier]) do |new_product|
            new_product.purchase = 'https://www.umich.edu/'
          end
          @lessees = product.lessees
        else
          @lessees = Lessee.all
        end
      end

      def show
        return head :not_found if @lessee.blank?
        if params[:product_identifier].present? # rubocop:disable Style/GuardClause
          product = Product.find_by(identifier: params[:product_identifier])
          return head :not_found if product.blank?
          return head :not_found unless product.lessees.include?(@lessee)
        end
      end

      def create # rubocop:disable Metrics/CyclomaticComplexity
        status = :ok
        product = if params[:product_identifier].present?
                    Product.find_or_create_by!(identifier: params[:product_identifier]) do |new_product|
                      new_product.purchase = 'https://www.umich.edu/'
                    end
                  end
        @lessee = Lessee.find_by(identifier: lessee_params[:identifier])
        if @lessee.blank?
          @lessee = Lessee.new(lessee_params)
          return render json: @lessee.errors, status: :unprocessable_entity unless @lessee.save
          status = :created
        end
        if product.present? && @lessee.present? && !product.lessees.include?(@lessee)
          product.lessees << @lessee
        end
        render :show, status: status, location: @lessee
      end

      def update # rubocop:disable Metrics/CyclomaticComplexity
        status = :ok
        product = if params[:product_identifier].present?
                    Product.find_or_create_by!(identifier: params[:product_identifier]) do |new_product|
                      new_product.purchase = 'https://www.umich.edu/'
                    end
                  end
        if @lessee.blank?
          @lessee = Lessee.new(identifier: params[:identifier])
          return render json: @lessee.errors, status: :unprocessable_entity unless @lessee.save
          status = :created
        end
        if product.present? && @lessee.present? && !product.lessees.include?(@lessee)
          product.lessees << @lessee
        end
        render :show, status: status, location: @lessee
      end

      def destroy # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        if params[:product_identifier].present?
          product = Product.find_by(identifier: params[:product_identifier])
          if product.present? && @lessee.present? && product.lessees.include?(@lessee)
            product.lessees.delete(@lessee)
          end
        else
          return head :ok if @lessee.blank?
          return head :accepted unless @lessee.products.empty?
          @lessee.delete
        end
        head :ok
      end

      private

        # Use callbacks to share common setup or constraints between actions.
        def set_lessee
          @lessee = Lessee.find_by(identifier: params[:identifier])
        end

        # Never trust parameters from the scary internet, only allow the white list through.
        def lessee_params
          params.require(:lessee).permit(:identifier)
        end
    end
  end
end
