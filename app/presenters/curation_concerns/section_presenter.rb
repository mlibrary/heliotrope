module CurationConcerns
  class SectionPresenter < WorkShowPresenter
    def monograph_label
      member_of.first.fetch('title_tesim', []).first
    end

    private

      def member_of
        @member_of ||= begin
          member_id_field = Solrizer.solr_name('member_ids', :symbol)
          ActiveFedora::SolrService.query("{!terms f=#{member_id_field}}#{id}").map { |res| SolrDocument.new(res) }
        end
      end
  end
end
