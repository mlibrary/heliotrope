class PublisherPresenter < ApplicationPresenter
  attr_reader :publisher

  def initialize(current_user, publisher)
    super(current_user)
    @publisher = publisher
  end

  delegate :id, :name, :subdomain, to: :@publisher
end
