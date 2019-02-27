# frozen_string_literal: true


desc "rake export monographs bags for a given press id"
namespace :aptrust do
  task :bag_given_press, [:press_name] => :environment do |_t, args|
    # Usage: Needs a valid press id as a parameter
    # $ ./bin/rails aptrust:bag_press[press_id]"

    puts "about to gather upload_docs from press #{args.press_name}"

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

      puts "back from gathering upload_docs with count #{upload_docs.count}"
      upload_docs
    end

    def find_record(noid)
      begin
        record = AptrustUpload.find_by!( noid: noid)
      rescue ActiveRecord::RecordNotFound => e
        # no record so create one
        puts "No record found for noid #{up_doc[:id]} with error #{e}"
        record = nil
      end
      record
    end

    def create_record(up_doc)
      begin
        record = AptrustUpload.create_by!(noid:  up_doc[:id])
      rescue ActiveRecord::RecordInvalid => e
        puts "Unable to create record for noid #{up_doc[:id]} with error #{e}"
        record = nil
      end
      record
    end

    def update_record(record, up_doc)
      bagged_date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      begin
        record.update_attributes(
                                  # noid:  up_doc[:id], # this is already in record
                                  press: up_doc['press_tesim'].first[0..49],
                                  author: up_doc["creator_tesim"].first[0..49],
                                  title: up_doc["title_tesim"].first[0..49],
                                  model: "monograph",
                                  bag_status: 0,
                                  s3_status: 0,
                                  apt_status: 0,
                                  date_monograph_modified: up_doc['date_modified_dtsi'],
                                  date_fileset_modified: nil,
                                  date_bagged: bagged_date,
                                  date_uploaded: nil,
                                  date_confirmed: nil
                                 )
      rescue ActiveRecord::RecordInvalid => e
        puts "Unable to update record for noid #{up_doc[:id]} with error #{e}"
        record = nil
      end
      record
    end

    upload_docs = get_solr_records(args.press_name)
    abort "WARNING in aptrust:bag_given_press upload_docs is NIL!" if upload_docs.nil?

    # Loop through each solr document and bag it
    upload_docs.each do |up_doc|

      record = find_record(up_doc[:id])

      if record.nil?
        record = create_record(up_doc[:id])
        record = update_record(record, up_doc)
      else
        record = update_record(record, up_doc)
      end

      if record.nil? # All good branchs failed
        puts "WARNING: Unable to create record for noid #{up_doc[:id]}"
      else
        puts "Have a good record now about to call exporter to create bag"
        exporter = Export::Exporter.new(up_doc.id, :monograph)
        exporter.export_bag
      end

    end # up_doc each
  end # task
end # namespace
