# frozen_string_literal: true

class PressesController < ApplicationController
  load_and_authorize_resource find_by: :subdomain, except: [:index]

  def index
    # get `/presses` out of search engine indexes, only show Presses index to platform and press admins
    if current_user.blank? || !(current_ability&.current_user&.platform_admin? || current_ability&.current_user&.admin_presses&.any?)
      render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
      return
    end

    authorize!(:index, Press)
    @presses = Press.all
  end

  def new
    @press = Press.new
  end

  def create
    @press = Press.create(press_params)
    if @press.save
      redirect_to presses_path
    else
      render :new, layout: false
    end
  end

  def edit; end

  def update
    if @press.update(press_params)
      redirect_to presses_path
    else
      render :edit, layout: false
    end
  end

  def destroy?
    publisher = Sighrax::Publisher.from_press(@press)
    !(publisher.children.present? || publisher.user_ids.present? || publisher.work_noids.present?)
  end

  def destroy
    @press.destroy if destroy?
    respond_to do |format|
      format.html { redirect_to fulcrum_partials_path(:refresh), notice: "Publisher was #{@press.destroyed? ? 'successfully': 'NOT'} destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def press_params
      params.require(:press).permit(:subdomain,
                                    :name,
                                    :logo_path,
                                    :description,
                                    :press_url,
                                    :google_analytics,
                                    :typekit,
                                    :footer_block_a,
                                    :footer_block_b,
                                    :footer_block_c,
                                    :remove_logo_path,
                                    :parent_id,
                                    :restricted_message,
                                    :twitter,
                                    :location,
                                    :google_analytics_url,
                                    :readership_map_url,
                                    :share_links,
                                    :watermark,
                                    :doi_creation,
                                    :navigation_block,
                                    :default_list_view,
                                    :aboutware,
                                    :interval
                                  )
    end
end
