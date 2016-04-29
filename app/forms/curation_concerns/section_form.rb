module CurationConcerns
  class SectionForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::Section

    self.terms = [:title,
                  :monograph_id,
                  :ordered_member_ids,
                  :visibility_during_embargo,
                  :embargo_release_date,
                  :visibility_after_embargo,
                  :visibility_during_lease,
                  :lease_expiration_date,
                  :visibility_after_lease,
                  :visibility]

    self.required_fields = [:title, :monograph_id]
    # :files, :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo, :visibility_during_lease, :lease_expiration_date, :visibility_after_lease, :visibility, :ordered_member_ids]
  end
end
