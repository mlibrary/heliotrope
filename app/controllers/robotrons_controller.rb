# frozen_string_literal: true

class RobotronsController < ApplicationController
  STATES = %w[AL AK AS AZ AR CA CO CT DE DC FL GA GU HI ID IL IN IA KS KY LA ME MD MH MA MI FM MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK OR PW PA PR RI SC SD TN TX UT VT VA VI WA WV WI WY].freeze

  before_action :set_robotron, only: %i[show trap destroy]

  def index
    @can_destroy = current_user&.platform_admin? || false
    Robotron.find_or_create_by(ip: request.ip || 0)
    @robotrons = Robotron.filter(filtering_params(params)).order(updated_at: :desc).page(params[:page])
  end

  def show
  end

  def trap
    @robotron.hits = @robotron.hits + 1
    @robotron.save!
    @robotron.reload
    @first_name = first_name
    @last_name = last_name
    @company = company
    @street = street
    @city = city
    @state = state
    @zipcode = zipcode
    @mobile = phone_number
    @fax = phone_number
    @email = email
    @trap_count = rand(99..999)
    @trap_paragraphs = []
    @trap_paths = []
    @trap_count.times do
      trap_paragraph = '<p>'
      rand(9..99).times do
        trap_paragraph += ' ' + Services.random_words.adj + ' ' + Services.random_words.noun
      end
      trap_paragraph += '</p>'
      @trap_paragraphs << trap_paragraph
      @trap_paths << Services.random_words.noun
    end
    render layout: false
  end

  def destroy
    @robotron.destroy
    respond_to do |format|
      format.html { redirect_to robotrons_url, notice: 'Robotron record was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

    protected

      def set_robotron
        @robotron = Robotron.find(params[:id])
      end

      def robotron_params
        params.require(:robotron).permit(:ip)
      end

      def filtering_params(params)
        params.slice(:ip_like, :hits_like, :updated_at_like)
      end

    private

      def first_name
        Services.random_words.noun
      end

      def last_name
        Services.random_words.noun
      end

      def company
        Services.random_words.adj
      end

      def street
        rand(1..99_999).to_s + ' ' + Services.random_words.adj
      end

      def city
        Services.random_words.noun
      end

      def state
        STATES[rand(0..(STATES.count - 1))]
      end

      def zipcode
        rand(10_000..99_999).to_s + '-' + rand(1_000..9_999).to_s
      end

      def phone_number
        "1-(900)-#{rand(100..999)}-#{rand(1000..9999)}"
      end

      def email
        "#{@first_name}_#{@last_name}@#{@company}.com"
      end
end
