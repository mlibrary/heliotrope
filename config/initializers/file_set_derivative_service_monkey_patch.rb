# frozen_string_literal: true

# See #1016
# When a file_set gets deleted it appears that for
# some reason this service gets called and it tries to get the mime_type
# of the file_set AFTER it's been deleted from fedora,
# so an Ldp::Gone error happens.
# This is the solution umrdr uses.
# TODO: Why is this being called generally on deletion, and
# why after the file_set's been deleted but not before?
Hyrax::FileSetDerivativesService.class_eval do
  def valid?
    supported_mime_types.include?(mime_type)
  rescue
    Rails.logger.warn("WARNING: config/initializers/file_set_derivative_monky_patch.rb happened!")
    nil
  end
end
