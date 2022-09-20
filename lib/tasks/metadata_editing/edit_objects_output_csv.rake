# frozen_string_literal: true

desc 'Take any number of NOIDs or ISBNs and output CSV to update them'
namespace :heliotrope do
  task edit_objects_output_csv: :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_objects_output_csv[/a_writable_folder/fulcrum_objects_to_edit.csv, noid1, noid2, isbn1,...]"
    object_hits = []

    ids = []
    file_path = ''

    fail "You must include a writable path and at least one object id (NOID or ISBN)" if args.extras.count < 2

    args.extras.each_with_index do |arg, index|
      # the first argument is the file path
      if index.zero?
        file_path = arg
      elsif arg.present?
        ids << arg
      end
    end

    puts ids.join(',')
    ids.each do |id|
      if !/^[[:alnum:]]$/.match?(id) && id.length < 9 && id.length > 13
        puts "Invalid identifier length (NOIDs and/or ISBNs are 9-13 alphanumeric characters): #{id} ........... SKIPPING"
        next
      end

      hits = ActiveFedora::SolrService.query("id:#{id} OR isbn_numeric:#{id}", rows: 100_000)

      if hits.count.zero?
        puts "No object found with identifier #{id} ............ SKIPPING"
        next
      elsif hits.count > 1
        puts "More than 1 object found with identifier #{id} ... SKIPPING" # should be impossible
        next
      else
        object_hits << hits.first
      end
    end

    if object_hits.count.zero?
      puts "No objects found. Nothing to output."
      exit
    end

    CSV.open(file_path, "w") do |csv|
      object_hits.each_with_index do |object_hit, index|
        doc = SolrDocument.new(object_hit)
        presenter = object_hit['has_model_ssim']&.first == 'Monograph' ? Hyrax::MonographPresenter.new(doc, nil) : Hyrax::FileSetPresenter.new(doc, nil)

        exporter = Export::Exporter.new(presenter.id, :all)
        exporter.write_csv_header_rows(csv) if index == 0
        csv << exporter.metadata_row(presenter)
      end
    end
    # a generic message helps when calling this task from heliotrope:edit_objects_via_csv
    puts "Ran 'heliotrope:edit_objects_output_csv': all object values written to #{file_path}"
  end
end
