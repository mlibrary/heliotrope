module PressHelper
  # Get the subdomain from any view that would have one
  def press_subdomain
    if defined?(@press.subdomain)
      @press.subdomain
    elsif defined?(@monograph_presenter.subdomain)
      @monograph_presenter.subdomain
    elsif defined?(@presenter.monograph.subdomain)
      @presenter.monograph.subdomain
    end
  end

  def google_analytics(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.google_analytics if press.present?
  end

  def typekit(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.typekit if press.present?
  end
end
