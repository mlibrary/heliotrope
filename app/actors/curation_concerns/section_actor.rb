module CurationConcerns
  class SectionActor < CurationConcerns::BaseActor
    protected

      def apply_save_data_to_curation_concern(attributes)
        maybe_set_monograph(attributes) do
          super
        end
      end

      def maybe_set_monograph(attributes)
        monograph = Monograph.find(attributes.delete('monograph_id')) if attributes.key?('monograph_id')
        yield
        if monograph
          monograph.ordered_members << curation_concern
          monograph.save!
        end
      end
  end
end
