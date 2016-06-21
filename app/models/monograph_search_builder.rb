# frozen_string_literal: true
class MonographSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [:filter_by_members]

  def filter_by_members(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=id}#{asset_ids(blacklight_params['id'])}"
  end

  private

    def asset_ids(monograph_id)
      assets = []
      Monograph.find(monograph_id).ordered_members.to_a.each do |om|
        # Get the file_set id, or if the work is a Section, get all of it's file_set ids
        assets << om.id if om.file_set?
        assets << Section.find(om.id).ordered_members.to_a.map(&:id) unless om.file_set?
      end

      assets.join(",") || ''
    end

    def work_types
      [FileSet]
    end
end
