# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
desc 'Generate a CSV summarising PDF conformance results from verapdf JSON files'
namespace :heliotrope do
  task :pdf_ebook_a11y_metadata_summary_from_json, [:input_dir, :output_file] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:pdf_ebook_a11y_metadata_summary_from_json[/path/to/json_dir]"
    #        bundle exec rake "heliotrope:pdf_ebook_a11y_metadata_summary_from_json[/path/to/json_dir, /path/to/output.csv]"
    #
    # Reads every *.json file under input_dir/**/ (organized in press-named subdirectories) and writes a CSV with:
    #   press, ISBN, <document_type hash keys>, is_tagged, <one column per conformance standard (status value)>

    require 'json'
    require 'csv'

    if args[:input_dir].blank?
      puts "An input directory must be provided. Usage: bundle exec rake \"heliotrope:pdf_ebook_a11y_metadata_summary_from_json[/path/to/json_dir]\""
      exit
    end

    input_dir = File.expand_path(args[:input_dir])

    unless Dir.exist?(input_dir)
      puts "Provided input directory (#{input_dir}) does not exist. Exiting."
      exit
    end

    unless File.readable?(input_dir)
      puts "Provided input directory (#{input_dir}) is not readable. Exiting."
      exit
    end

    output_path = args[:output_file] || File.join(input_dir, 'pdf_ebook_a11y_metadata_summary_from_json.csv')

    unless File.writable?(File.dirname(output_path))
      puts "Output directory (#{File.dirname(output_path)}) is not writable. Exiting."
      exit
    end

    json_files = Dir.glob(File.join(input_dir, '**', '*.json')).sort

    if json_files.empty?
      puts "No JSON files found under #{input_dir}. Exiting."
      exit
    end

    # First pass – parse all files and collect the union of document_type and conformance keys
    rows              = []
    doc_type_keys     = []
    conformance_keys  = []

    json_files.each do |path|
      data = JSON.parse(File.read(path))

      # user must manually store the JSON files for each press's Monographs in a press-named directory inside
      press          = File.basename(File.dirname(path))
      file_base_name = File.basename(path, '.*')
      document_type  = data['document_type'] || {}
      is_tagged      = data.dig('metadata', 'is_tagged')
      conformance    = data['conformance'] || {}

      doc_type_keys    |= document_type.keys
      conformance_keys |= conformance.keys

      rows << {
        press:          press,
        file_base_name: file_base_name,
        document_type:  document_type,
        is_tagged:      is_tagged,
        conformance:    conformance
      }
    end

    # Second pass – write CSV
    headers = ['press', 'file basename'] + doc_type_keys + ['is_tagged'] + conformance_keys

    CSV.open(output_path, 'w') do |csv|
      csv << headers

      rows.each do |row|
        line = [row[:press], row[:file_base_name]]
        doc_type_keys.each { |key| line << row[:document_type][key] }
        line << row[:is_tagged]
        conformance_keys.each { |key| line << row[:conformance].dig(key, 'status') }
        csv << line
      end
    end

    puts "Wrote #{rows.size} rows to #{output_path}"
  end
end
# rubocop:enable Metrics/BlockLength
