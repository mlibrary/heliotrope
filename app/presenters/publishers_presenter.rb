# frozen_string_literal: true

class PublishersPresenter < ApplicationPresenter
  def all
    (Press.all.map { |press| PublisherPresenter.new(@current_user, press) }).sort! { |x, y| x.name <=> y.name }
  end
end
