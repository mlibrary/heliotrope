# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {Name} object:
  #
  # ```json
  # {
  #   "given_name": "Franz",
  #   "surname": "Ferdinand",
  #   "familiar_name": "Franz",
  #   "display_name": "Franz Ferdinand (Personal)"
  # }
  # ```
  class Name < Base
    field :given_name, String
    field :surname, String
    field :familiar_name, String
    field :display_name, String
  end
end
