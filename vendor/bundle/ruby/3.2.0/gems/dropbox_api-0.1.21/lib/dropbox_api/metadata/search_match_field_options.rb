# frozen_string_literal: true

module DropboxApi::Metadata
  class SearchMatchFieldOptions < Base
    # Whether to include highlight span from file title. The default for
    # this field is False.
    field :include_highlights, :boolean, :optional
  end
end
