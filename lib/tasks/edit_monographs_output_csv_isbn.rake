# frozen_string_literal: true

desc 'Take any number of formatless, hyphenless Monograph ISBNs and output CSV to update them'
namespace :heliotrope do
  task edit_monographs_output_csv_isbn: :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_monographs_output_csv_isbn[/a_writable_folder/monographs.csv, isbn1, isbn2, isbn3,...]"
    output_monograph_csv_isbn(args)
  end

  def output_monograph_csv_isbn(args)
    monographs = []

    isbns = []
    file_path = ''
    args.extras.each_with_index do |arg, index|
      # the first argument is the file path
      if index.zero?
        file_path = arg
      else
        isbns << arg
      end
    end

    isbns.each do |isbn|
      matches = Monograph.where(isbn_ssim: isbn)
      if matches.count.zero?
        puts "No Monograph found with ISBN #{isbn} ............ EXITING"
        return
      elsif matches.count > 1
        puts "More than 1 Monograph found with ISBN #{isbn} ... EXITING" # shouldn't happen, but easily could
        return
      else
        monographs << matches.first
      end
    end

    CSV.open(file_path, "w") do |csv|
      monographs.each_with_index do |m, index|
        exporter = Export::Exporter.new(m.id, :monograph)
        exporter.write_csv_header_rows(csv) if index == 0
        csv << exporter.monograph_row
      end
    end
    # a generic message helps when calling this task from heliotrope:edit_monographs_via_csv_isbn
    puts "Ran 'heliotrope:edit_monographs_output_csv_isbn': all monograph values written to #{file_path}"
  end
end
