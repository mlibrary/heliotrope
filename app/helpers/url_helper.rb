# frozen_string_literal: true

module UrlHelper
  include Blacklight::UrlHelperBehavior

  ##
  # Attributes for a link that gives a URL we can use to track clicks for the current search session
  # @param [SolrDocument] document
  # @param [Integer] counter
  # @example
  #   session_tracking_params(SolrDocument.new(id: 123), 7)
  #   => { data: { :'tracker-href' => '/catalog/123/track?counter=7&search_id=999' } }
  def session_tracking_params(_document, _counter)
    # path = session_tracking_path(document, per_page: params.fetch(:per_page, search_session['per_page']), counter: counter, search_id: current_search_session.try(:id))

    # if path.nil?
    # return {}
    # end

    # { data: {:'context-href' => path } }
    #

    # HELIO-3449 Return {} so data-context-href="/catalog/<noid>/track?counter=<n>&locale=en&search_id=<id>" is not included in anchor tag.
    # Hence,
    #
    #   Blacklight.do_search_context_behavior = function() {
    #     $('a[data-context-href]').on('click.search-context', Blacklight.handleSearchContextMethod);
    #   };
    #
    # Will never happen.  See search_context.js in blacklight gem.
    {}
  end
  protected :session_tracking_params
end
