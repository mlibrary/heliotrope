module CurationConcerns
  class SectionPresenter < WorkShowPresenter
    include TitlePresenter

    attr_accessor :monograph_presenter

    def monograph_id
      Array(solr_document['monograph_id_ssim']).first
    end

    def monograph
      @monograph_presenter ||= PresenterFactory.build_presenters([monograph_id], MonographPresenter, current_ability).first
    end

    def monograph_label
      member_of.first.fetch('title_tesim', []).first
    end

    # In CurationConcerns::WorkShowPresenter this method would produce an endless loop.
    # The representative_id of the Section points to the FileSet.
    # The FileSet's representative_id is then used to call representative_presenter,
    # which then uses that same FileSet representative_id to call a representative_presenter, etc, etc.
    # This override is simplistic but works for our Sections which contain only FileSets,
    # no recursion needed
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||= CurationConcerns::PresenterFactory.build_presenters([representative_id], CurationConcerns::FileSetPresenter, current_ability).first
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
