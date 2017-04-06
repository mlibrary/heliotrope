class PublishersPresenter < ApplicationPresenter
  def all
    (Press.all.map { |press| PublisherPresenter.new(@current_user, press) }).sort! { |x, y| x.subdomain <=> y.subdomain }
  end
end
