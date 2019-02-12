# frozen_string_literal: true

NOTUPLOADED = 0

desc "rake export monographs bags for a given press id"
namespace :aptrust do
  task :bag_given_press, [:press_id] => :environment do |_t, args|
    # Usage: Needs a valid press id as a parameter
    # $ ./bin/rails aptrust:bag_press[press_id]"

    ## open connection to db 'fulcrum_aptrust' as user 'fulcrum_aptrust'


    upload_docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:#{args.press_id} AND +visibility_ssi:'open'",
                                             fq: '-suppressed_bsi:true',
                                             fl: ['id', 'press_tesim', 'author_tesim', 'description_tesim', 'identifier_tesim', 'title_tesim', 'date_modified_tesim', 'date_uploaded_dtsi'],
                                             sort: 'date_uploaded_dtsi asc',
                                             rows: 100000)

    upload_doc.each do |up_doc|

      # this_row = SELECT ALL FROM monograph WHERE noid_id = doc.id
      ## if this_row <> NULL
        # this_mono_bagged = row['date_bagged']
      ## else
        # INSERT INTO monograph(noid_id,
                                # press,
                                # author
                                # title,
                                # date_monograph_modified,
                                # date_files_modified,
                                # date_bagged,
                                # date_uploaded_apt,
                                # s3_status,
                                # apt_status)

        # VALUES(doc.id,
                  # doc.press,
                  # doc.author[0..500],
                  # doc.title[0..500],
                  # doc.modified_date,
                  # NULL,
                  # NULL,
                  # NULL,
                  # NULL,
                  # NULL);
        # this_mono_bagged = NULL
      ## end

      # if this_mono_bagged == NULL
        exporter = Export::Exporter.new(doc.id, :monograph)
        exporter.export_bag
      #end

      ## if no errors
        # timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        # update monographs
        # set date_bagged = timestamp, 
        #     s3_status = NOTUPLOADED
        # where noid_id = doc.id;
      ## end

    end # up_doc each
  ## close db 'fulcrum_aptrust' connection
  end # task
end
