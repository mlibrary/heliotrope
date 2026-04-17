# frozen_string_literal: true

desc 'Output specific fields for all BAR Monographs with separated ISBNs'
namespace :heliotrope do
  task :bar_monographs_report_with_separated_isbns, [:directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:bar_monographs_report_with_separated_isbns[/a_writable_folder]"

    if args.directory.blank?
      puts "No directory provided. Exiting."
      exit
    end

    unless Dir.exist?(args.directory)
      puts "Provided directory (#{args.directory}) does not exist. Exiting."
      exit
    end

    unless File.writable?(args.directory)
      puts "Provided directory (#{args.directory}) is not writable. Exiting."
      exit
    end

    if Press.find_by(subdomain: 'barpublishing').blank?
      puts "Subdomain (barpublishing) does not exist. Exiting."
      exit
    end

    file_path = File.join(args.directory, "barpublishing_monographs_report_with_separated_isbns_#{Time.now.getlocal.strftime("%Y-%m-%d")}.csv")

    docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:barpublishing", rows: 100_000)

    CSV.open(file_path, "w") do |csv|
      csv << ["Monograph Title/Link", "BAR Number", "Author", "print ISBN", "ebook ISBN", "Published?", "Tombstoned?"]
      docs.each do |doc|
        isbns = doc['isbn_tesim']&.map(&:strip)&.reject(&:blank?) || []

        csv << ["=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id)}\", \"#{doc['title_tesim']&.first&.gsub('"', '""')}\")",
                bar_number_for_bar_monographs_report_with_separated_isbns(doc),
                doc['creator_tesim']&.first&.gsub('"', '""'),
                print_isbn(isbns),
                online_isbn(isbns),
                doc['visibility_ssi'] == 'open' ? 'YES' : 'NO',
                doc['tombstone_ssim']&.first == 'yes' ? 'YES' : 'NO']
      end
    end

    puts "BAR Monograph report with separated ISBNs saved to #{file_path}"
  end
end


def bar_number_for_bar_monographs_report_with_separated_isbns(doc)
  doc['identifier_tesim']&.find { |i| i[/^bar_number:.*/] }&.gsub('bar_number:', '')&.strip
end

def print_isbn(isbns)
  priority_list = {
    "hardcover" => 1,
    "hardback" => 2,
    "cloth" => 3,
    "Hardcover" => 4,
    "print" => 5,
    "hardcover : alk. paper" => 6,
    "hc. : alk. paper" => 7,
    "paperback" => 8,
    "paper" => 9,
    "Paper" => 10,
    "pb." => 11,
    "pb. : alk. paper" => 12,
    "paper with cd" => 13,
    "paper plus cd rom" => 14
  }

  priority_isbn(isbns, priority_list)
end

def online_isbn(isbns)
  # Prefer OA ISBNs over other kinds
  priority_list = {
    "open access" => 1,
    "open-access" => 2,
    "OA" => 3,
    "ebook" => 4,
    "e-book" => 5,
    "epub" => 6,
    "ebook epub" => 7,
    "PDF" => 8,
    "ebook pdf" => 9,
    "pdf" => 10
  }

  priority_isbn(isbns, priority_list)
end

def priority_isbn(isbns, priority_list)
  results = {}
  isbns.each do |isbn|
    matches = isbn.match(/^(.*)\s*\((.*)\)/)
    if matches.present?
      isbn_numbers = matches[1].delete("-")
      type = matches[2]
      results[priority_list[type]] = isbn_numbers
    end
  end

  results.delete(nil)
  return "" if results.empty?

  results.sort_by { |k, _v| k }.first&.last || ""
end
