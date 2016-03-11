module CurationConcerns
  class SectionActor < CurationConcerns::BaseActor
    include ::CurationConcerns::WorkActorBehavior

    protected

      def apply_save_data_to_curation_concern
        monograph = Monograph.find(attributes.delete('monograph_id'))
        super
        monograph.members << curation_concern
        monograph.save!
      end
  end
end
