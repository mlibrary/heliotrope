# frozen_string_literal: true

class ScoreCatalogController < ::CatalogController
  before_action :load_presenter, only: %i[index facet]

  self.theme = 'curation_concerns'
  with_themed_layout 'catalog'

  configure_blacklight do |config|
    config.search_builder_class = ScoreSearchBuilder

    config.index.partials = %i[thumbnail index_header index]

    config.index_fields.tap do
      config.index_fields.delete('human_readable_type_tesim')
    end
  end

  def facet
    super
  end

  private

    def load_presenter
      score_id = params[:score_id] || params[:id]
      raise CanCan::AccessDenied unless current_ability&.can?(:read, score_id)
      @presenter = Hyrax::PresenterFactory.build_for(ids: [score_id], presenter_class: Hyrax::ScorePresenter, presenter_args: current_ability).first
      @ebook_download_presenter = EBookDownloadPresenter.new(@presenter, current_ability, current_actor)
    end
end
