# frozen_string_literal: true

class FullTextCatalogController < ::CatalogController
  before_action :load_presenter, only: %i[index]

  self.theme = 'hyrax'

  configure_blacklight do |config| # rubocop:disable Metrics/BlockLength
    config.search_builder_class = FullTextSearchBuilder
    config.index.partials = %i[thumbnail index_header index]
  end

  def facet
    super
  end

  private

    def load_presenter
      retries ||= 0
      monograph_id = params[:monograph_id] || params[:id]
      raise CanCan::AccessDenied unless current_ability&.can?(:read, monograph_id)
      @presenter = Hyrax::PresenterFactory.build_for(ids: [monograph_id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
      auth_for(Sighrax.from_presenter(@presenter))
    rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
      Rails.logger.error(%Q|[RSOLR ERROR TRY:#{retries}] #{e} #{e.backtrace.join("\n")}|)
      retries += 1
      retry if retries < 3
    end
end
