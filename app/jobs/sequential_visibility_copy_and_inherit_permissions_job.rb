# frozen_string_literal: true

class SequentialVisibilityCopyAndInheritPermissionsJob < Hyrax::ApplicationJob
  def perform(work)
    VisibilityCopyJob.perform_now(work)
    InheritPermissionsJob.perform_now(work)
  end
end
