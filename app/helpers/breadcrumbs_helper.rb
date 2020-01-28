# frozen_string_literal: true

module BreadcrumbsHelper
  mattr_accessor :crumbs

  def breadcrumbs # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return [] if @presenter.nil?
    return [] if press.blank?
    @crumbs = []

    aboutware_home if has_aboutware?

    if press.parent_id.present?
      crumb_parent_press
    else
      crumb_press_home
    end

    case controller_name
    when "press_statistics"
      press_statistics
    when "score_catalog"
      work_catalog
    when "monograph_catalog"
      work_catalog
    when "monographs"
      curation_concerns_monograph_show
    when "file_sets"
      file_sets
    end
    @crumbs
  end

  private

    def file_sets
      @crumbs << if @presenter.parent.is_a? Hyrax::MonographPresenter
                   { href: main_app.monograph_catalog_path(@presenter.parent.id), text: @presenter.parent.title, class: "" }
                 elsif @presenter.parent.is_a? Hyrax::ScorePresenter
                   { href: main_app.score_catalog_path(@presenter.parent.id), text: @presenter.parent.title, class: "" }
                 end
      @crumbs << { href: "", text: @presenter.title, class: "active" }
    end

    def curation_concerns_monograph_show
      @crumbs << { href: main_app.monograph_catalog_path(@presenter.id), text: @presenter.title, class: "" }
      @crumbs << { href: "", text: 'Show', class: "active" }
    end

    def work_catalog
      @crumbs << { href: "", text: @presenter.title, class: "active" }
    end

    def press_statistics
      @crumbs << { href: "", text: t('press_catalog.statistics'), class: "active" }
    end

    def crumb_parent_press
      parent = Press.find(press.parent_id)
      if has_aboutware?
        @crumbs << { href: main_app.press_catalog_path(parent), text: t('monograph_catalog.index.catalog'), class: "" }
      else
        @crumbs << { href: main_app.press_catalog_path(parent), text: t('monograph_catalog.index.home'), class: "" }
      end
      @crumbs << { href: main_app.press_catalog_path(press), text: press.name, class: "" }
    end

    def crumb_press_home
      if has_aboutware?
        @crumbs << { href: main_app.press_catalog_path(press), text: t('monograph_catalog.index.catalog'), class: "" }
      else
        @crumbs << { href: main_app.press_catalog_path(press), text: I18n.t('monograph_catalog.index.home'), class: "" }
      end
    end

    def aboutware_home
      @crumbs << { href: press.press_url, text: t('breadcumbs.home'), class: "" } if has_aboutware?
    end

    def has_aboutware?
      press.navigation_block.present?
    end

    def press
      @press ||= if defined?(@presenter.subdomain)
                   Press.where(subdomain: @presenter.subdomain)&.first
                 elsif defined?(@presenter.parent.subdomain)
                   Press.where(subdomain: @presenter.parent.subdomain)&.first
                 else
                   ""
                 end
    end
end
