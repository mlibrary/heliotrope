# frozen_string_literal: true

require 'net/http'
require 'uri'

desc "Check where DOI redirects actually lead"
namespace :heliotrope do
  task :doi_checker, [:output_directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:doi_checker[output_directory]"

    if !File.writable?(args.output_directory)
      puts "Provided directory (#{args.output_directory}) is not writable. Exiting."
      exit
    end

    output_file = File.join(args.output_directory, "doi_resolution_check-#{Time.now.getlocal.strftime("%Y-%m-%d")}.csv")

    docs = ActiveFedora::SolrService.query('+doi_ssim:["" TO *]', fl: ['id', 'doi_ssim', 'has_model_ssim', 'title_tesim', 'visibility_ssi'], rows: 100_000)

    CSV.open(output_file, "w") do |csv|
      csv << %w[model link doi published resolved\ url ends\ on\ Fulcrum? destination\ contains\ noid?]
      docs.each do |doc|
        final_url = follow_redirections("https://doi.org/#{doc['doi_ssim']&.first}")

        ends_on_fulcrum = final_url.start_with?('fulcrum.org') || final_url.start_with?('www.fulcrum.org') ||
          final_url.start_with?('https://fulcrum.org') || final_url.start_with?('http://fulcrum.org') ||
          final_url.start_with?('https://www.fulcrum.org') || final_url.start_with?('http://www.fulcrum.org')

        destination_contains_noid = final_url.exclude?('ArgumentError') && final_url.include?(doc.id)

        published = doc['visibility_ssi'] == 'open'

        if doc['has_model_ssim']&.first == 'Monograph'
          csv << ['Monograph', "=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id)}\", \"#{doc['title_tesim']&.first.gsub('"', '""')}\")", doc['doi_ssim']&.first, published, final_url, ends_on_fulcrum, destination_contains_noid]
        else
          csv << ['FileSet', "=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_file_set_url(doc.id)}\", \"#{doc['title_tesim']&.first.gsub('"', '""')}\")", doc['doi_ssim']&.first, published, final_url, ends_on_fulcrum, destination_contains_noid]
        end
      end
    end

    puts "All Monograph and FileSet DOI resolution data saved to #{output_file}"
  end
end

# https://stackoverflow.com/a/59226408
# On very rare occasions (once or twice per run) this seems to return the DOI link itself when it actually *has* been...
# registered. Might be a burp on Crossref's end and/or a timing issue here. It's easy to find these when examining...
# the mistakenly-unregistered DOIs. Not sure if waiting/retrying would work around this. No biggie as-is though.
def follow_redirections(url)
  begin
    response = Net::HTTP.get_response(URI(url))
    until response['location'].nil?
      response = Net::HTTP.get_response(URI(response['location']))
    end
  rescue StandardError => e
    return "ArgumentError following #{url} --- #{e}"
  end
  response.uri.to_s
end
