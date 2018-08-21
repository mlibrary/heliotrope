# frozen_string_literal: true

desc 'Output CSV file for HEB Monographs containing weird creator values'
namespace :heliotrope do
  task heb_creator_changes: :environment do
    # Usage: Needs a valid datetime as a parameter
    # $ bundle exec rake "heliotrope:heb_qc_csv[2018-06-08T00:00:00-05:00]"

    filename = '/tmp/heliotrope_heb_creator_changes.csv'
    line_count = 0

    CSV.open(filename, "w") do |csv|
      csv << ['HEB ID', 'Title (link)', 'edit', 'New Creators Value', 'Old Creators Value']

      Monograph.where(press_sim: 'heb').each do |m|
        original_value = m.creator.first
        next if original_value.blank?

        # if ['[', ']', '(', ')'].any? { |char| m.creator.first&.include?(char) }
        no_parens = original_value&.gsub(/\(.*?\)/, '')&.gsub(/\[.*?\]/, '')
        # end

        names = no_parens.split(/\r?\n/).reject(&:blank?).map(&:strip)

        new_names = []
        names.each do |name|
          new_names << name.split(',').reject(&:blank?).map(&:strip).first(2).join(', ')
        end

        new_names = new_names.count > 1 ? new_names.join("\r\n") : new_names.first

        next if original_value == new_names

        csv << [m.identifier.find { |i| i[/^heb.*/] },
                '=HYPERLINK("' + Rails.application.routes.url_helpers.hyrax_monograph_url(m.id) + '","' + m.title.first.gsub('"', '""') + '")',
                '=HYPERLINK("' + Rails.application.routes.url_helpers.edit_hyrax_monograph_url(m.id) + '","edit")',
                new_names,
                original_value]
        line_count += 1
      end
    end
    puts 'Output (' + line_count.to_s + ' lines) written to ' + filename
  end
end
