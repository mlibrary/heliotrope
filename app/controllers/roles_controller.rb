# frozen_string_literal: true

##
# CRUD actions for assigning press roles to
# existing users
class RolesController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource :press, find_by: :subdomain, except: %i[index2 show]
  load_and_authorize_resource through: :press, except: %i[update_all index2 show]

  def index
    role = @press.roles.build
    authorize! :edit, role
  end

  def update_all
    authorize_nested_attributes! press_params[:roles_attributes], Role

    if @press.update(press_params)
      notice = any_deleted ? t(:'helpers.submit.role.destroyed') : t(:'helpers.submit.role.updated')
      redirect_to press_roles_path(@press), notice: notice
    else
      flash[:alert] = t(:'helpers.submit.role.batch_error')
      render action: 'index'
    end
  end

  protected

    def press_params
      params.require(:press).permit(roles_attributes: %i[id user_key role _destroy])
    end

    def any_deleted
      press_params[:roles_attributes].values.any? do |item|
        item['_destroy'].present? && item['_destroy'] != 'false'
      end
    end

    # When nested attributes are passed in, ensure we have authorization to update each row.
    # @param attrs [Hash, Array] the nested attributes
    # @param klass [Class] the class that is getting created
    # @return [Integer] a count of the number of deleted records
    def authorize_nested_attributes!(attrs, klass)
      attrs.each do |_, item|
        authorize_item item, klass
      end
    end

    def authorize_item(item, klass)
      if item[:id]
        if item['_destroy'].present?
          authorize! :destroy, klass.find(item[:id])
        else
          authorize! :update, klass.find(item[:id])
        end
      else
        authorize! :create, klass
      end
    end
end
