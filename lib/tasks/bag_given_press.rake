# frozen_string_literal: true
desc "rake export monographs bags for a given press id"
namespace :aptrust do
  task :bag_given_press, [:press_name] => :environment do |_t, args|
    # Usage: Needs a valid press id as a parameter
    # $ ./bin/rails aptrust:bag_press['press_name’]"
    BAG_STATUSES = {'not_bagged' => 0, 'bagged' => 1, 'bagging_failed' => 3}.freeze
    S3_STATUSES = {'not_uploaded' => 0, 'uploaded' => 1, 'upload_failed' => 3}.freeze
    APT_STATUSES = {'not_checked' => 0, 'confirmed' => 1, 'pending' => 3, 'failed' => 4}.freeze
    
    error_array = []
    # upload_docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:#{args.press_id} AND +visibility_ssi:'open'",
    #                                          fq: '-suppressed_bsi:true',
    #                                          fl: ['id', 'press_tesim', 'author_tesim', 'description_tesim', 'identifier_tesim', 'title_tesim', 'date_modified_tesim', 'date_uploaded_dtsi'],
    #                                          sort: 'date_uploaded_dtsi asc',
    #                                          rows: 100000)
      # children = @press.children.pluck(:subdomain)
      # presses = children.push(@press.subdomain).uniq
    def get_solr_records(press)
      docs = ActiveFedora::SolrService.query("{!terms f=press_sim}#{press}", rows: 100_000)
      upload_docs = docs.select { |doc| doc["suppressed_bsi"] == false && doc["visibility_ssi"] == "open" }
      puts "back from gathering upload_docs with document count #{upload_docs.count}" unless upload_docs.nil?
      upload_docs
    end
    def find_record(noid, error_array)
      begin
        record = AptrustUpload.find_by!(noid: noid)
      rescue ActiveRecord::RecordNotFound => e
        error_array << "find_record error is #{e} "
        record = nil
      end
      record
    end
    def create_record(noid, error_array)
      begin
        record = AptrustUpload.create!(noid:  noid)
      rescue AptrustUpload::RecordInvalid => e
        error_array << "create_record error is #{e} "
        record = nil
      end
      record
    end
    def update_record(record, up_doc, error_array)
      begin
        record.update!(
                        # noid:  up_doc[:id], # this is already in record
                        press: up_doc['press_tesim'].first[0..49],
                        author: up_doc["creator_tesim"].first[0..49],
                        title: up_doc["title_tesim"].first[0..49],
                        model: up_doc["has_model_ssim"].first[0..49],
                        bag_status: BAG_STATUSES['not_bagged'],
                        s3_status: S3_STATUSES['not_uploaded'],
                        apt_status: APT_STATUSES['not_checked'],
                        date_monograph_modified: up_doc['date_modified_dtsi'],
                        date_fileset_modified: nil,
                        date_bagged: nil,
                        date_uploaded: nil,
                        date_confirmed: nil
                      )
      rescue ActiveRecord::RecordInvalid => e
        error_array << "record.update error is #{e} "
        record = nil
      end
      record
    end
    puts "About to gather upload_docs from press #{args.press_name}"
    upload_docs = get_solr_records(args.press_name)
    abort "WARNING in aptrust:bag_given_press upload_docs is NIL!" if upload_docs.nil?
    # Loop through each solr document and bag it
    upload_docs.each do |up_doc|
      record = find_record(up_doc[:id], error_array)
      record = create_record(up_doc[:id], error_array) if record.nil?
      record = update_record(record, up_doc, error_array) unless record.nil?
      if record.nil? # All good branchs failed
        puts "WARNING: Unable to find or create record for noid #{up_doc[:id]}"
        puts "Errors were: #{error_array.to_s}"
      else
        exporter = Export::Exporter.new(up_doc[:id], :monograph)
        exporter.export_bag
      end
    end # up_doc each      
  end # task
end # namespace
