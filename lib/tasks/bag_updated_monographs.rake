# frozen_string_literal: true

desc "rake export monographs bags for a given press id"
namespace :aptrust do
  task :bag_updated_monographs => :environment do |_t, args|
    # Usage: Needs a valid press id as a parameter
    # $ ./bin/rails "aptrust:bag_new_and_updated_monographs"

    BAG_STATUSES = { 'not_bagged' => 0, 'bagged' => 1, 'bagging_failed' => 3 } .freeze
    S3_STATUSES = { 'not_uploaded' => 0, 'uploaded' => 1, 'upload_failed' => 3 }.freeze
    APT_STATUSES = { 'not_checked' => 0, 'confirmed' => 1, 'pending' => 3, 'failed' => 4 }.freeze

    # SAVING FOR POSSIBLE LATER USE
    # upload_docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:#{args.press_id} AND +visibility_ssi:'open'",
    #                                          fq: '-suppressed_bsi:true',
    #                                          fl: ['id', 'press_tesim', 'author_tesim', 'description_tesim', 'identifier_tesim', 'title_tesim', 'date_modified_tesim', 'date_uploaded_dtsi'],
    #                                          sort: 'date_uploaded_dtsi asc',
    #                                          rows: 100000)

    # children = @press.children.pluck(:subdomain)
    # presses = children.push(@press.subdomain).uniq

    # subsequent runs:
    # - use Solr calls to pull all *published* Monographs with their mod dates and child ids
    def monographs_solr_all_published
      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph", rows: 100_000)
      published_docs = docs.select { |doc| doc["suppressed_bsi"] == false && doc["visibility_ssi"] == "open" }

      puts "back from gathering published_docs with document count #{published_docs.count}" unless published_docs.nil?
      published_docs
    end

    def find_record(noid)
      begin
        record = AptrustUpload.find_by!(noid: noid)
      rescue ActiveRecord::RecordNotFound => e
        puts "Error in find_record for noid #{noid}: #{e}"
        record = nil
      end
      record
    end

    def create_record(noid)
      begin
        record = AptrustUpload.create!(noid:  noid)
      rescue AptrustUpload::RecordInvalid => e
        puts "Error in create_record for noid #{noid}: #{e}"
        record = nil
      end
      record
    end

    def update_record(record, noid)
      # first get the monograph
      update_docs = ActiveFedora::SolrService.query('+has_model_ssim:Monograph AND +press_sim:heb AND +visibility_ssi:restricted',
                                      fq: "id:#{noid}",
                                      fl: ['id', 'press_tesim', "creator_tesim", 'identifier_tesim', 'title_tesim', 'date_uploaded_dtsi', "has_model_ssim"])
      update_docs.each do |update_doc|
        begin
          record.update!(
                          # noid:  up_doc[:id], # this is already in record
                          press: update_doc['press_tesim'].first[0..49],
                          author: update_doc["creator_tesim"].first[0..49],
                          title: update_doc["title_tesim"].first[0..49],
                          model: update_doc["has_model_ssim"].first[0..49],
                          bag_status: BAG_STATUSES['not_bagged'],
                          s3_status: S3_STATUSES['not_uploaded'],
                          apt_status: APT_STATUSES['not_checked'],
                          date_monograph_modified: update_doc['date_modified_dtsi'],
                          date_fileset_modified: nil,
                          date_bagged: nil,
                          date_uploaded: nil,
                          date_confirmed: nil
                        )
        rescue ActiveRecord::RecordInvalid => e
          puts "Error in update_record for noid #{noid}: #{e}"
          record = nil
        end
      end
      record
    end

    def create_bag(record, noid)
      if record.nil?
        puts "WARNING: nil record for noid #{noid}. We should never see this error!"
      else
        exporter = Export::Exporter.new(noid, :monograph)
        exporter.export_bag
      end
    end

    def check_mono_fileset_mod_dates(record, doc, recreate_bag_ids)
      doc_fsets = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND +monograph_id_ssim:#{doc[:id]}", rows: 100_000)
      return if doc_fsets.blank?

      record_bagged_time = DateTime.parse(record.date_bagged.to_s).utc
      # puts "record.date_bagged parse utc is #{record_bagged_time}"

      add_to_recreate = false
      doc_fsets.each do |fset|
        unless add_to_recreate
        # puts "fset['date_modified_dtsi'] is #{fset['date_modified_dtsi']}"
          fset_time = DateTime.parse(fset['date_modified_dtsi']).utc
          # puts "In doc noid #{doc[:id]} for fset #{fset.id} date_modified_dtsi parse to utc is #{fset_time}"
          add_to_recreate = (fset_time > record_bagged_time)
          recreate_bag_ids << doc[:id] if add_to_recreate
          puts "add_to_recreate is #{add_to_recreate} for fset #{fset.id} and noid #{doc[:id]}" if add_to_recreate
        end
      end
    end

    published_docs = monographs_solr_all_published

    abort "WARNING in aptrust:bag_given_press published_docs is NIL!" if published_docs.nil?

    new_bag_ids = []
    recreate_bag_ids = []

    # # Check solr docs for ones that represent new or update monographs
    published_docs.each do |doc|
      puts "doc :id is #{doc[:id]}"
      record = find_record(doc[:id])
      if record.nil?
        puts "In published_docs loop record was nil"
        new_bag_ids << doc[:id]
      elsif record.bag_status.zero?
        puts "In published_docs loop bag_status was zero"
        new_bag_ids << doc[:id]
      # elsif doc modified date is more recent that bagged date
      elsif doc['date_modified_dtsi'] > record.date_bagged
        puts "In published_docs loop doc modified date is greater than db date_bagged"
        recreate_bag_ids << doc[:id]
      else
        puts "In published_docs loop, checking fileset date against date_bagged"
        # if any of the docs filesets modified date is more recent that bagged date
        # will add to recreate_bag_ids
        check_mono_fileset_mod_dates(record, doc, recreate_bag_ids)
      end
    end

    puts "new_bag_ids array is #{new_bag_ids}"

    new_bag_ids.each do |noid|
      record = create_record(noid)
      if record.nil?
        puts "In new bags could not create a record for noid #{noid}"
      else
        record = update_record(record, noid)
        if record.nil?
          puts "In new bags could not update_record a record for noid #{noid}"
        else
          puts "In new bags about to create a bag for noid #{noid} and record #{record}"
          create_bag(record, noid)
        end
      end
    end

    puts "recreate_bag_ids array is #{recreate_bag_ids}"

    recreate_bag_ids.each do |noid|
      record = find_record(noid)
      if record.nil?
        puts "In recreate bags could not find a record for noid #{noid}"
      else
        record = update_record(record, noid)
        if record.nil?
          puts "In recreate bags could not update_record a record for noid #{noid}"
        else
          puts "In recreate bags about to create a bag for noid #{noid} and record #{record}"
          create_bag(record, noid)
        end
      end
    end
  end
end
