# When you create records in fedora, hydra requires that there is a user_key listed as the depositor of the record.  Since we don't have a real user to act as the depositor when we run the importer, we have a dummy user that isn't persisted to the database.

# In curation_concerns version 0.12.0, the method signatures of some of the background jobs have been changed so that they take a User as an argument instead of a (String) user_key.  As a result, we had errors when globalid tried to convert the (non-existent) user ID to a global id.  So, I added this DummyUser class to provide the needed behavior.

# This class is meant to be used by the command-line importer, not by the Rails app itself.  In the future, if we add batch import functionality to the UI, we should just pass the currently logged in user instead of a dummy user.

# This is the change in curation_concerns:
# https://github.com/projecthydra-labs/curation_concerns/commit/71ed9ffb301e627364ff139a99d0f63b68a31903#diff-5c5a2367b1c1932f845a06b05eda218eR9

class DummyUser < User
  def to_global_id
    user_key
  end
end
