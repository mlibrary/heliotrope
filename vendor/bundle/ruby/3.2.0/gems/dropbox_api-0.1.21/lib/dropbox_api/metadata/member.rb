# frozen_string_literal: true
module DropboxApi::Metadata
  # Examples of serialized {AddMember} objects:
  #
  # ```json
  # [
  #   {
  #     ".tag": "email",
  #     "email": "justin@example.com"
  #   },  {
  #     ".tag": "dropbox_id",
  #     "dropbox_id": "dbid:AAEufNrMPSPe0dMQijRP0N_aZtBJRm26W4Q"
  #   }
  # ]
  # ```
  class Member < Base
    def initialize(member)
      @member_hash = case member
        when Hash
          member
        when String
          hash_from_email_or_dropbox_id member
        when DropboxApi::Metadata::Member
          member.to_hash
        else
          raise ArgumentError, "Invalid object for Member: #{member.inspect}"
        end
    end

    def to_hash
      @member_hash
    end

    private

    def hash_from_email_or_dropbox_id(email_or_id)
      if email_or_id.start_with? 'dbid:'
        hash_from_dropbox_id email_or_id
      elsif email_or_id =~ /\A[^@\s]+@[^@\s]+\z/
        hash_from_email email_or_id
      else
        raise ArgumentError, "Invalid email or Dropbox ID: #{email_or_id}"
      end
    end

    def hash_from_dropbox_id(dropbox_id)
      {
        ".tag": :dropbox_id,
        dropbox_id: dropbox_id
      }
    end

    def hash_from_email(email)
      {
        ".tag": :email,
        email: email
      }
    end
  end
end
