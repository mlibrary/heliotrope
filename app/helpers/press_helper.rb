# frozen_string_literal: true

module PressHelper
  mattr_accessor :press_presenter

  def press_presenter
    @press_presenter ||= if defined?(@press.subdomain)
                           PressPresenter.for(@press.subdomain)
                         elsif defined?(@presenter.subdomain)
                           PressPresenter.for(@presenter.subdomain)
                         elsif defined?(@presenter.parent.subdomain)
                           PressPresenter.for(@presenter.parent.subdomain)
                         else
                           # This will be the null object
                           PressPresenter.for(nil)
                         end
  end
end
