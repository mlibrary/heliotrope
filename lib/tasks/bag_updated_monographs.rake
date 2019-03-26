# frozen_string_literal: true

desc "rake export monographs bags for a given press id"
namespace :aptrust do
  task :bag_updated_monographs => :environment do |_t, args|
    # Usage: Needs a valid press id as a parameter
    # $ ./bin/rails "aptrust:bag_new_and_updated_monographs"

    BAG_STATUSES = { 'not_bagged' => 0, 'bagged' => 1, 'bagging_failed' => 3 } .freeze
    S3_STATUSES = { 'not_uploaded' => 0, 'uploaded' => 1, 'upload_failed' => 3 }.freeze
    APT_STATUSES = { 'not_checked' => 0, 'confirmed' => 1, 'pending' => 3, 'failed' => 4 }.freeze

    DEBUG = false

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
        record = nil
      end
      record
    end

    def create_record(noid)
      begin
        record = AptrustUpload.create!(noid:  noid)
      rescue AptrustUpload::RecordInvalid => e
        record = nil
      end
      record
    end

    def update_record(record)
      solr_monographs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph",
                                      fq: "id:#{record.id}",
                                      fl: ['id', 
                                          'press_tesim', 
                                          'creator_tesim', 
                                          'identifier_tesim', 
                                          'title_tesim', 
                                          'date_uploaded_dtsi', 
                                          'has_model_ssim'])
      puts "solr_monographs count is: #{solr_monographs.count}"
      data = solr_monographs.first
        begin
          record.update!(
                          # noid:  up_doc[:id], # this is already in record
                          press: data['press_tesim'].first[0..49],
                          author: data["creator_tesim"].first[0..49],
                          title: data["title_tesim"].first[0..249],
                          model: data["has_model_ssim"].first[0..49],
                          bag_status: BAG_STATUSES['not_bagged'],
                          s3_status: S3_STATUSES['not_uploaded'],
                          apt_status: APT_STATUSES['not_checked'],
                          date_monograph_modified: data['date_modified_dtsi'],
                          date_fileset_modified: nil,
                          date_bagged: nil,
                          date_uploaded: nil,
                          date_confirmed: nil
                        )
        rescue ActiveRecord::RecordInvalid => e
          record = nil
        end
      record
    end

    def create_bag(record)
      if record.nil?
        puts "WARNING: nil record for noid in create_bag. We should never see this error!"
      else
        exporter = Export::Exporter.new(record.id, :monograph)
        exporter.export_bag
      end
    end

    def check_mono_mod_date(record, pdoc)
      need_to_recreate = false
      record_bagged_time = DateTime.parse(record.date_bagged.to_s).utc
      pub_pdoc_time = DateTime.parse(pdoc['date_modified_dtsi'].to_s).utc
      need_to_recreate = (pub_pdoc_time > record_bagged_time)
    end

    def check_mono_fileset_mod_dates(record, pdoc)
      # Try to get the filesets for this published monograph; if there are none return false
      pdoc_fsets = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND +monograph_id_ssim:#{pdoc[:id]}", rows: 100_000)
      return false if pdoc_fsets.blank?

      # Get date_bagged from database
      return false if record.date_bagged.blank?
      record_bagged_time = DateTime.parse(record.date_bagged.to_s).utc

      need_to_recreate = false

      # Loop through filesets to see if any have a newer date than the db date_bagged
      pdoc_fsets.each do |fset|
        # if we found a newer date stop checking
        unless need_to_recreate
          fset_time = DateTime.parse(fset['date_modified_dtsi']).utc
          need_to_recreate = (fset_time > record_bagged_time)
        end
      end
      need_to_recreate
    end

    def update_db_aptrust_status(record)
      filename = Rails.root.join('config', 'aptrust.yml')
      yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
      @aptrust = yaml || nil
      abort "Not getting authentication secrets via @aptrust yml" if @aptrust.nil?

      heads = {}
      heads["Content-Type"] = "application/json"
      heads["Accept"] = "application/json"
      heads["X-PHAROS-API-USER"] = @aptrust['AptrustApiUser']
      heads["X-PHAROS-API-KEY"] = @aptrust['AptrustApiKey']

      base_apt_url = @aptrust['AptrustApiUrl']
      bag_name = "umich.fulcrum-#{record['press']}-#{record['id']}"

      updated_after = Time.parse(record['date_uploaded'].to_s) - (60 * 60 * 24)
      updated_after = updated_after.iso8601

      this_url = base_apt_url + "items/?per_page=200&action=ingest&name=#{bag_name}&updated_after=#{updated_after}"
      puts "this_url: #{this_url}" if DEBUG

      response = Typhoeus::Request.new(this_url, headers: heads).run

      if DEBUG
        puts "response.code: #{response.code}"
        puts "response.total_time: #{response.total_time}"
        puts "response.headers: #{response.headers}"
        puts "response.body: #{response.body}"
      end

      parsed = JSON.parse(response.response_body)

      if DEBUG
        put "count is #{parsed['count']}" unless parsed.nil?
      end

      if parsed["results"].nil?
        puts "WARNING: In update_aptrust_status got no data back from aptrust api"
        return
      end

      if DEBUG
        puts parsed["results"] unless parsed["results"].nil?
        puts "parsed['results'].count is #{parsed['results'].count}" unless parsed["results"].nil?
      end

      # We might get back more than one matching aptrust record
      # the following handles that possibility by find the most current one
      saved_results = {}

      parsed["results"].each do |res|
        current_results = res

        # See if we've already stored a subhash for this noid
        if saved_results.empty?
          saved_results = current_results
        else
          puts "Some dates, saved_results['bag_date']: #{saved_results['bag_date']} and current_results['bag_date'] #{current_results['bag_date']}" if DEBUG
          saved_datetime = DateTime.parse(saved_results['bag_date'].to_s).utc
          current_datetime = DateTime.parse(current_results['bag_date'].to_s).utc

          # Replace saved_results with current_results if current bag_date is newer
          saved_results = current_results if current_datetime > saved_datetime
        end
      end

      case saved_results['status']
      when 'Success'
        apt_key = 'confirmed'
      when 'Failed', 'Cancelled'
        apt_key = 'failed'
      when 'Started', 'Pending'
        apt_key = 'pending'
      else
        apt_key = 'failed'
      end

      # UPDATE RECORD WITH STATUS HERE
      puts "Update record #{record['id']}with apt_key #{apt_key} and status code #{APT_STATUSES[apt_key]}"
      begin
        record.update!(
                        apt_status: APT_STATUSES[apt_key]
                      )
      rescue ActiveRecord::RecordInvalid => e
        record = nil
      end
      record
    end

    solr_monographs = monographs_solr_all_published

    abort "WARNING in aptrust:bag_updated_monographs published_docs is NIL!" if solr_monographs.nil?

    # SORT SOLR PUBLISHED MONOGRAPHS INTO ARRAYS
    create_bag_ids = []

    # Check solr docs for ones that represent new or update monographs
    # pdoc means published monograph
    solr_monographs.each do |pdoc|
      record = find_record(pdoc[:id])
      if record.nil?
        # There is no db record
        create_bag_ids << pdoc[:id]
      elsif record.bag_status == BAG_STATUSES['not_bagged']
        # There is a db record but this noid hasn't been bagged yet
        create_bag_ids << pdoc[:id]
      elsif check_mono_mod_date(record, pdoc)
        # if doc modified date is more recent that db bagged date
        create_bag_ids << pdoc[:id]
      elsif check_mono_fileset_mod_dates(record, pdoc)
        # If any of the docs filesets modified date is more recent that db bagged date
        create_bag_ids << pdoc[:id]
      else
        # Otherwise check deposit for this pdoc in aptrust and update DB
        check = update_db_aptrust_status(record)
        puts "Error return from update_db_aptrust_status in bag_updated_monographs" if check.nil?
      end
    end

    # CREATE BAGS
    create_bag_ids.each do |noid|
      record = find_record(noid)
      if record.nil?
        puts "In create bag ids could not find a record for noid #{noid}, will try to create one"
        record = create_record(noid)
        if record.nil?
          puts "In create bag ids could not create a record for noid #{noid}"
        else
          record = update_record(record)
          if record.nil?
            puts "In create bag ids could not update_record a record for noid #{noid}"
          else
            puts "In create bag ids about to create a bag for noid #{noid} and record #{record}"
            create_bag(record)
          end
        end
      end
    end
  end
end
