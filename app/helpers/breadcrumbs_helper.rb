# frozen_string_literal: true

module BreadcrumbsHelper
  def breadcrumbs
    return [] if @presenter.nil?

    crumbs = case controller_name
             when "file_sets"
               breadcrumbs_for_file_set(@presenter.monograph.subdomain, @presenter)
             when "monographs"
               breadcrumbs_for_monograph_show_page(@presenter.subdomain, @presenter)
             when "monograph_catalog"
               breadcrumbs_for_monograph(@presenter.subdomain, @presenter)
             end

    crumbs || []
  end

  private

    def breadcrumbs_for_monograph(subdomain, presenter)
      press = Press.where(subdomain: subdomain)&.first
      return [] if press.blank?

      crumbs = possible_parent(press)
      crumbs << { href: "", text: presenter.title, class: "active" }
    end

    def breadcrumbs_for_monograph_show_page(subdomain, presenter)
      press = Press.where(subdomain: subdomain)&.first
      return [] if press.blank?

      crumbs = possible_parent(press)
      crumbs << { href: main_app.monograph_catalog_path(presenter.id), text: presenter.title, class: "" }
      crumbs << { href: "", text: 'Show', class: "active" }
    end

    def breadcrumbs_for_file_set(subdomain, presenter)
      press = Press.where(subdomain: subdomain)&.first
      return [] if press.blank?

      crumbs = possible_parent(press)
      crumbs << { href: main_app.monograph_catalog_path(presenter.monograph_id), text: presenter.monograph.title, class: "" }
      crumbs << { href: "", text: presenter.title, class: "active" }
    end

    def possible_parent(press)
      crumbs = []
      if press.parent_id.present?
        parent = Press.find(press.parent_id)
        crumbs << { href: main_app.press_catalog_path(parent), text: translate('monograph_catalog.index.home'), class: "" }
        crumbs << { href: main_app.press_catalog_path(press), text: press.name, class: "" }
      else
        crumbs << { href: main_app.press_catalog_path(press), text: translate('monograph_catalog.index.home'), class: "" }
      end
      crumbs
    end
end
