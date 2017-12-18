# frozen_string_literal: true

module BreadcrumbsHelper
  def breadcrumbs
    crumbs = if @presenter.present? && @presenter.class == Hyrax::FileSetPresenter
               breadcrumbs_for_file_set(@presenter.monograph_presenter.subdomain, @presenter)
             elsif @monograph_presenter.present?
               breadcrumbs_for_monograph(@monograph_presenter.subdomain, @monograph_presenter)
             end
    crumbs || []
  end

  private

    def breadcrumbs_for_monograph(subdomain, presenter)
      press = Press.where(subdomain: subdomain)&.first
      return [] if press.blank?

      crumbs = possible_parent(press)
      crumbs << { href: "", text: presenter.page_title, class: "active" }
    end

    def breadcrumbs_for_file_set(subdomain, presenter)
      press = Press.where(subdomain: subdomain)&.first
      return [] if press.blank?

      crumbs = possible_parent(press)
      crumbs << { href: main_app.monograph_catalog_path(presenter.monograph_id), text: presenter.monograph.page_title, class: "" }
      crumbs << { href: "", text: presenter.page_title, class: "active" }
    end

    def possible_parent(press)
      crumbs = []
      if press.parent_id.present?
        parent = Press.find(press.parent_id)
        crumbs << { href: "/#{parent.subdomain}", text: translate('monograph_catalog.index.home'), class: "" }
        crumbs << { href: "/#{press.subdomain}", text: press.name, class: "" }
      else
        crumbs << { href: "/#{press.subdomain}", text: translate('monograph_catalog.index.home'), class: "" }
      end
      crumbs
    end
end
