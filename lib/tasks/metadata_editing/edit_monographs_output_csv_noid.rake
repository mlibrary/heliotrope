# frozen_string_literal: true

desc 'Take any number of Monograph NOIDs and output CSV to update them'
namespace :heliotrope do
  task edit_monographs_output_csv_noid: :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_monographs_output_csv_noid[/a_writable_folder/monographs.csv, noid1, noid2, noid3,...]"
    output_monograph_csv_noid(args)
  end

  def output_monograph_csv_noid(args)
    noid_chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    monographs = []

    noids = []
    file_path = ''
    args.extras.each_with_index do |arg, index|
      # the first argument is the file path
      if index.zero?
        file_path = arg
      else
        noids << arg
      end
    end

    noids.each do |noid|
      if noid.length != 9 || !noid.chars.all? { |ch| noid_chars.include?(ch) }
        puts "Invalid NOID detected: #{noid} .................. EXITING"
        return
      end

      matches = Monograph.where(id: noid)
      if matches.count.zero?
        puts "No Monograph found with NOID #{noid} ............ EXITING"
        return
      elsif matches.count > 1
        puts "More than 1 Monograph found with NOID #{noid} ... EXITING" # impossible
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
    # a generic message helps when calling this task from heliotrope:edit_monographs_via_csv_noid
    puts "Ran 'heliotrope:edit_monographs_output_csv_noid': all monograph values written to #{file_path}"
  end
end
