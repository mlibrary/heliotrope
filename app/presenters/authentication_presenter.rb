# frozen_string_literal: true

class AuthenticationPresenter < ApplicationPresenter
  private_class_method :new

  attr_reader :file_set_presenter

  delegate :actor_unauthorized?, :return_location,
           :publisher?, :publisher_subdomain, :publisher_name, :publisher_display_name, :publisher_individual_subscribers?,
           :publisher_subscribing_institutions,
           :monograph?, :monograph_buy_url?, :monograph_buy_url, :monograph_worldcat_url?, :monograph_worldcat_url,
           :monograph_subscribing_institutions,
           to: :@auth

  def self.for(actor, subdomain, id, filter)
    entity = Sighrax.from_noid(id)
    file_set_presenter = nil
    monograph_presenter = nil
    case entity
    when Sighrax::Resource
      file_set_presenter = Hyrax::PresenterFactory.build_for(ids: [entity.noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [entity.parent.noid], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first
    when Sighrax::Monograph
      monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [entity.noid], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first
    end
    press_presenter = PressPresenter.for(monograph_presenter&.subdomain || subdomain)
    press_presenter = nil if press_presenter.blank?
    new actor, press_presenter, monograph_presenter, file_set_presenter, filter
  end

  def page_title
    'Authentication'
  end

  def page_class
    'press'
  end

  def subdomain
    publisher_subdomain
  end

  def institutions
    if @filter
      @institutions = monograph_subscribing_institutions
    else
      @institutions = publisher_subscribing_institutions
    end
  end

  def monograph_other_options?
    monograph? && (monograph_buy_url? || monograph_worldcat_url?)
  end

  private

    def initialize(actor, press_presenter, monograph_presenter = nil, file_set_presenter = nil, filter = nil)
      @actor = actor
      @press_presenter = press_presenter
      @monograph_presenter = monograph_presenter
      @file_set_presenter = file_set_presenter
      @filter = filter.present?
      @auth = if @file_set_presenter.present?
                Auth.new(@actor, Sighrax.from_presenter(@file_set_presenter))
              elsif @monograph_presenter.present?
                Auth.new(@actor, Sighrax.from_presenter(@monograph_presenter))
              elsif @press_presenter.present?
                Auth.new(@actor, Sighrax::Publisher.from_press(@press_presenter.press))
              else
                Auth.new(@actor, Sighrax::Entity.null_entity)
              end
    end
end
