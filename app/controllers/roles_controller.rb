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

  # *All* of a Press's roles are sent through as params here every time one of the Save buttons is clicked.
  # This action would be a lot less confusing if the UI made it clear that all edits are sent along with *any* "Save"...
  # button, i.e. there should only be one Save button on that form where there actually is one on every row.
  # Also the if the delete action were a checkbox instead of a button per row/role, that would make better sense also.
  def update_all
    authorize_nested_attributes! press_params[:roles_attributes], Role

    if @press.update(press_params)
      notice = if any_new_roles?
                 t(:'helpers.submit.role.added')
               elsif any_deleted
                 t(:'helpers.submit.role.destroyed')
               else
                 t(:'helpers.submit.role.updated')
               end
      redirect_to press_roles_path(@press), notice: notice
    else
      # See HELIO-112. If we're here then something went wrong and, even though this action is a bizarre mix of...
      # create/update/delete, the failure can really only be the *one* new record that (may) have been added. Which...
      # has to be the last one in the `roles_attributes` hash, with has no `id` set. See `any_added?`.
      # This is an example of what `roles_attributes` looks like in JSON.
      # {"roles_attributes":{"0":{"id":"2","user_key":"me@mine.com","role":"analyst","_destroy":"false"},
      #                      "1":{"id":"3","user_key":"blah@blah.edu","role":"analyst","_destroy":"false"},
      #                      "2":{"user_key":"test@testy.tv","role":"admin"}}}
      failed_user_key = new_role_user_key

      if failed_user_key.present?
        user = User.find_by(user_key: failed_user_key)

        if user.blank?
          flash[:alert] = t(:'helpers.submit.role.user_missing')
        elsif Role.find_by(user_id: user.id, resource_type: 'Press', resource_id: Press.find_by(subdomain: params[:press_id]).id).present?
          flash[:alert] = t(:'helpers.submit.role.a_role_exists')
        end
      else
        flash[:alert] = t(:'helpers.submit.role.batch_error')
      end
      render action: 'index'
    end
  end

  protected

    def press_params
      params.require(:press).permit(roles_attributes: %i[id user_key role _destroy])
    end

    def any_new_roles?
      press_params[:roles_attributes].values.any? do |item|
        item['id'].blank?
      end
    end

    def new_role_user_key
      user_key = nil
      press_params[:roles_attributes].values.any? do |item|
        user_key = item['user_key'] if item['id'].blank?
      end
      user_key
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
