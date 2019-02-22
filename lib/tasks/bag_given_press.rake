# frozen_string_literal: true


desc "rake export monographs bags for a given press id"
namespace :aptrust do
  task :bag_given_press, [:press_name] => :environment do |_t, args|
    # Usage: Needs a valid press id as a parameter
    # $ ./bin/rails aptrust:bag_press[press_id]"

    ## open connection to db 'fulcrum_aptrust' as user 'fulcrum_aptrust'

    puts "about to gather upload_docs from press #{args.press_name}"

    # upload_docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:#{args.press_id} AND +visibility_ssi:'open'",
    #                                          fq: '-suppressed_bsi:true',
    #                                          fl: ['id', 'press_tesim', 'author_tesim', 'description_tesim', 'identifier_tesim', 'title_tesim', 'date_modified_tesim', 'date_uploaded_dtsi'],
    #                                          sort: 'date_uploaded_dtsi asc',
    #                                          rows: 100000)

      # children = @press.children.pluck(:subdomain)
      # presses = children.push(@press.subdomain).uniq
    docs = ActiveFedora::SolrService.query("{!terms f=press_sim}#{args.press_name}", rows: 100_000)
    upload_docs = docs.select { |doc| doc["suppressed_bsi"] == false && doc["visibility_ssi"] == "open" }

    puts "back from gathering upload_docs with count #{upload_docs.count}"

    upload_docs.each do |up_doc|

      updoc_id = up_doc[:id]
      puts "current upload_doc is #{updoc_id}"
      puts
      # up_doc.inspect

      record = AptrustUpload.find_by noid: updoc_id

      if record.present?

      # if AptrustUpload.where(noid: updoc_id).exists?
        puts "WARNING: Record found for noid #{updoc_id}"
      else
        timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        new_record = AptrustUpload.find_or_create_by(
                                noid:  up_doc[:id],
                                press: up_doc['press_tesim'].first[0..49],
                                author: up_doc["creator_tesim"].first[0..49],
                                # title: up_doc["title_tesim"].first[0..49], # HAVE TO ADD TITLE TO MIGRATION!
                                model: "monograph",
                                bag_status: 0,
                                s3_status: 0,
                                apt_status: 0,
                                date_monograph_modified: up_doc['date_modified_dtsi'],
                                date_fileset_modified: nil,
                                date_bagged: timestamp,
                                date_uploaded: nil,
                                date_confirmed: nil
                                )
        new_record.save!

        puts "about to call exporter"
        exporter = Export::Exporter.new(up_doc.id, :monograph)
        exporter.export_bag
      end

    end # up_doc each
  ## close db 'fulcrum_aptrust' connection
  end # task
end # namespace
