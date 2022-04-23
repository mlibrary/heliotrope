# frozen_string_literal: true

# HandleJob is responsible for maintaining default handles for all Monographs and FileSets.
#
# It is kicked off daily by cron via the rake task heliotrope:handle
#
# desc 'Update Handle Records'
# namespace :heliotrope do
#   task handle: :environment do
#     HandleJob.perform_later
#     p "HandleJob.perform_later"
#   end
# end
#
# It uses the database table 'handle_deposits' to keep track of all the default Monograph and FileSet handles.
# The table has a 'noid' field for the Monograph/Fileset noid, an 'action' field for the action to be performed, and
# a 'verified' field to flag if the 'action' was successful. The 'updated_at' field is used to track the last time a noid
# was know to exist a.k.a. the last time the solr query 'model_docs' return a solr document with ['id'] == noid.
#
# The first thing it does is "Delete all action delete verified records older than 30 days ago" or in other words,
# Delete all the 'handle_deposits' records that have an action of 'delete' that has been 'verified' (a.k.a. verified
# is true) and the solr query 'model_docs' hasn't return the 'noid' for over thirty days.
#
# Why thirty days you may ask, well, if production (fulcrum.org) hasn't been up and running in the last thirty days
# that would be one serious outage! Basically after thirty days one may safely assume the Monograph/FileSet
# no longer exist in the production system.
#
# The next thing it does is loop through all the 'model_docs' and finds (or creates) a 'handle_deposit' record for each
# document. The record is 'touched' so the 'updated_at' is set to 'now', hence 'handle_deposit' records for noids not
# in 'model_docs' will age. If the record action is NOT 'create' it will set the record's action to 'create' and set the
# record's 'verified' flag to false. Finally it will save the record.
#
# Why set the record's action to 'create' and verified flag to 'false' you may ask, well, if it is a new record the
# action will be 'null' but since it is a new record it means a new noid which means a new Monograph/FileSet so
# logically we need to create a new handle. The only other action it could be is 'delete' but the noid was found
# in the 'model_docs' so that can't be right, something must of went wrong yesterday so recreate the handle just to be safe.
#
# The next thing it does is set the action to 'delete' and the verified flag to 'false' for all untouched records older
# than 30 days ago. In other words, if a noid hasn't been seen in the 'model_docs' for over 30 days one may safely
# assume the Monograph/FileSet was deleted so it 'should' be safe to delete the handle. This assumption may not be
# true in all context in which case the untouched record should be manually deleted if for some reasons the handle
# needs to exist even though the Monograph/FileSet has been deleted.
#
# With all the bookkeeping done it will create handles for all the records that have a create action and a verified
# flag of false, delete handles for all the records that have a delete action and a verified flag of false, then
# finally verify that handles were created and deleted. If verification fails, no biggy, the verified flag is still
# false and it will try tomorrow to create or delete the handle.
#
# NOTE: Once the production system has over 100_000 Monographs and FileSets no more handles will be created OR
# handles will start being created and deleted sporadically based on which 100_000 of the 100_000+ Monographs
# and FileSets were returned in the 'model_docs' that particular day. Hopefully that will never happens because
# that would be bad and 100_000 limit is also being using in the APTrust code.

class HandleJob < ApplicationJob
  def perform
    # Delete all action delete verified records older than 30 days ago
    HandleDeposit.where("updated_at <= ?", HandleJob.thirty_days_ago).where(action: 'delete', verified: true).delete_all

    # Force create action for all existing models
    model_docs.each do |model_doc|
      record = HandleDeposit.find_or_create_by(noid: model_doc['id'])
      record.touch # rubocop:disable Rails/SkipsModelValidations
      next if /^create$/.match?(record.action)

      record.action = 'create'
      record.verified = false
      record.save
    end

    # Force delete action for all untouched records older than 30 days ago
    HandleDeposit.where("updated_at <= ?", HandleJob.thirty_days_ago).where.not(action: 'delete').each do |record|
      record.action = 'delete'
      record.verified = false
      record.save
    end

    # Create handles for existing models
    HandleDeposit.where(action: 'create', verified: false).each do |record|
      HandleCreateJob.perform_now(record.noid)
    end

    # Delete handles of deleted models
    HandleDeposit.where(action: 'delete', verified: false).each do |record|
      HandleDeleteJob.perform_now(record.noid)
    end

    # Verify creation/deletion of handles
    HandleDeposit.where(verified: false).each do |record|
      HandleVerifyJob.perform_now(record.noid)
    end

    # Return true to simplify unit test a.k.a. it { is_expected.to be true }
    true
  end

  def model_docs
    ActiveFedora::SolrService.query(
      "+(has_model_ssim:Monograph OR has_model_ssim:FileSet)",
      fl: %w[id has_model_ssim],
      rows: 100_000
    ) || []
  end

  # Makes unit test easier to write
  def self.thirty_days_ago
    30.days.ago
  end
end
