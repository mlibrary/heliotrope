# frozen_string_literal: true

require 'csv'
require 'set'

module CounterSummaryService
  class CsvProcessor
    attr_reader :year, :month, :errors

    # Required CSV columns
    REQUIRED_COLUMNS = [
      'Identifier',
      'Total_Item_Requests (for the month)',
      'Total_Item_Requests (life to date)',
      'Total_Item_Investigations (for the month)',
      'Total_Item_Investigations (life to date)',
      'Unique_Item_Requests (for the month)',
      'Unique_Item_Requests (life to date)',
      'Unique_Item_Investigations (for the month)',
      'Unique_Item_Investigations (life to date)'
    ].freeze

    # Processing constants
    PROGRESS_LOG_INTERVAL = 1000  # Log progress every N rows
    SOLR_BATCH_SIZE = 500        # Maximum identifiers per Solr query
    MAX_IDENTIFIER_ERRORS = 100   # Stop collecting identifier errors after this many

    def initialize(year, month)
      @year = year
      @month = month
      @errors = []
      @identifier_errors = 0
      @total_missing_identifiers = 0
    end

    # Process a CSV file and return an array of hashes ready to save
    # Returns: Array of hashes with monograph_noid and all metric values
    #
    # Memory Usage: This method loads the entire CSV into memory. For very large files
    # (100K+ rows), memory usage could be significant (~50-100MB per 100K rows).
    # Monitor memory if file sizes grow substantially.
    def process_file(csv_path)
      return [] unless File.exist?(csv_path)

      return [] unless validate_csv_headers(csv_path)

      raw_data = parse_csv(csv_path)
      grouped_data = group_by_monograph(raw_data)
      roll_up_metrics(grouped_data)
    end

    private

      # Validate that CSV has required columns
      def validate_csv_headers(csv_path)
        first_line = File.open(csv_path, &:readline)
        headers = CSV.parse_line(first_line) || []

        missing_columns = REQUIRED_COLUMNS.reject { |col| headers.include?(col) }

        if missing_columns.any?
          @errors << "CSV missing required columns: #{missing_columns.join(', ')}"
          Rails.logger.error "#{self.class.name}: CSV validation failed - missing columns: #{missing_columns.join(', ')}"
          return false
        end

        Rails.logger.info "#{self.class.name}: CSV headers validated successfully"
        true
      rescue StandardError => e
        @errors << "CSV header validation error: #{e.message}"
        Rails.logger.error "#{self.class.name}: CSV header validation error: #{e.message}"
        false
      end

      # Parse CSV file with SIQ COUNTER statistics
      # Expected CSV column format from SIQ:
      #   - Identifier
      #   - Total_Item_Requests (for the month)
      #   - Total_Item_Requests (life to date)
      #   - Total_Item_Investigations (for the month)
      #   - Total_Item_Investigations (life to date)
      #   - Unique_Item_Requests (for the month)
      #   - Unique_Item_Requests (life to date)
      #   - Unique_Item_Investigations (for the month)
      #   - Unique_Item_Investigations (life to date)
      def parse_csv(csv_path)
        data = []
        CSV.foreach(csv_path, headers: true) do |row|
          identifier = row['Identifier']&.strip
          next if identifier.blank?

          data << {
            identifier: identifier,
            total_item_requests_month: safe_int(row['Total_Item_Requests (for the month)']),
            total_item_requests_life: safe_int(row['Total_Item_Requests (life to date)']),
            total_item_investigations_month: safe_int(row['Total_Item_Investigations (for the month)']),
            total_item_investigations_life: safe_int(row['Total_Item_Investigations (life to date)']),
            unique_item_requests_month: safe_int(row['Unique_Item_Requests (for the month)']),
            unique_item_requests_life: safe_int(row['Unique_Item_Requests (life to date)']),
            unique_item_investigations_month: safe_int(row['Unique_Item_Investigations (for the month)']),
            unique_item_investigations_life: safe_int(row['Unique_Item_Investigations (life to date)'])
          }
        end
        data
      rescue CSV::MalformedCSVError => e
        @errors << "CSV parsing error: #{e.message}"
        []
      end

      # Safely convert value to integer, returning 0 for nil/blank
      def safe_int(value)
        value&.to_i || 0
      end

      # Group all data by parent monograph noid using batch Solr queries
      def group_by_monograph(raw_data)
        return {} if raw_data.empty?

        total_rows = raw_data.length
        Rails.logger.info "#{self.class.name}: Processing #{total_rows} rows"

        # Extract all unique identifiers (memory-efficient - avoid pluck)
        identifiers = Set.new
        raw_data.each { |row| identifiers << row[:identifier] }
        unique_count = identifiers.size
        Rails.logger.info "#{self.class.name}: Found #{unique_count} unique identifiers"

        # Batch lookup monograph noids
        noid_map = batch_find_monographs(identifiers.to_a)
        Rails.logger.info "#{self.class.name}: Mapped #{noid_map.size} identifiers to monographs"

        # Group rows by their monograph noid
        monograph_data = Hash.new { |h, k| h[k] = [] }
        raw_data.each_with_index do |row, index|
          # Log progress every PROGRESS_LOG_INTERVAL rows
          if (index % PROGRESS_LOG_INTERVAL).zero? && index > 0
            progress_pct = ((index.to_f / total_rows) * 100).round(1)
            Rails.logger.info "#{self.class.name}: Grouped #{index}/#{total_rows} rows (#{progress_pct}%)"
          end

          identifier = row[:identifier]
          monograph_noid = noid_map[identifier]

          if monograph_noid
            monograph_data[monograph_noid] << row
          else
            @total_missing_identifiers += 1
            # Only log first N identifier errors to avoid log spam
            if @identifier_errors < MAX_IDENTIFIER_ERRORS
              @errors << "Could not find monograph for identifier: #{identifier}"
              @identifier_errors += 1
            elsif @identifier_errors == MAX_IDENTIFIER_ERRORS
              @errors << "... and more identifier errors (logging suppressed)"
              @identifier_errors += 1
            end
          end
        end

        Rails.logger.info "#{self.class.name}: Grouped into #{monograph_data.keys.length} monographs (#{@total_missing_identifiers} identifiers not found)"
        monograph_data
      end

      # Batch lookup monograph noids for all identifiers with batched Solr queries
      # Handles: monograph noids, file_set noids, and chapter identifiers (noid.NNNN)
      # Returns: Hash mapping identifier -> monograph_noid
      def batch_find_monographs(identifiers)
        return {} if identifiers.empty?

        # Separate chapter IDs and extract their parent file_set noids
        chapter_ids = identifiers.select { |id| id =~ /^\w+\.\d+$/ }
        file_set_noids_from_chapters = chapter_ids.map { |id| id.split('.').first }.uniq
        direct_noids = identifiers.reject { |id| id =~ /^\w+\.\d+$/ }

        # Combine all noids we need to query
        all_noids = (direct_noids + file_set_noids_from_chapters).uniq

        return {} if all_noids.empty?

        Rails.logger.info "#{self.class.name}: Querying Solr for #{all_noids.length} identifiers"

        # Query Solr in batches to avoid hitting maxBooleanClauses limit
        noid_to_doc = {}
        all_noids.each_slice(SOLR_BATCH_SIZE).with_index do |noid_batch, batch_index|
          Rails.logger.info "#{self.class.name}: Solr batch #{batch_index + 1}: querying #{noid_batch.length} identifiers"

          docs = ActiveFedora::SolrService.query(
            "{!terms f=id}#{noid_batch.join(',')}",
            fl: ['id', 'has_model_ssim', 'monograph_id_ssim'],
            rows: noid_batch.length
          )

          docs.each { |doc| noid_to_doc[doc['id']] = doc }

          Rails.logger.info "#{self.class.name}: Solr batch #{batch_index + 1}: found #{docs.length} documents"
        rescue StandardError => e
          @errors << "Batch Solr query error (batch #{batch_index + 1}): #{e.message}"
          Rails.logger.error "#{self.class.name}: Solr batch error: #{e.message}"
        end

        # Build result map
        result_map = {}

        # Process direct identifiers (monographs and file_sets)
        direct_noids.each do |noid|
          doc = noid_to_doc[noid]
          next unless doc

          model = doc['has_model_ssim']&.first
          if model == 'Monograph'
            result_map[noid] = noid
          elsif model == 'FileSet'
            result_map[noid] = doc['monograph_id_ssim']&.first
          end
        end

        # Process chapter identifiers - map to their file_set's monograph
        chapter_ids.each do |chapter_id|
          file_set_noid = chapter_id.split('.').first
          doc = noid_to_doc[file_set_noid]
          next unless doc

          if doc['has_model_ssim']&.first == 'FileSet'
            result_map[chapter_id] = doc['monograph_id_ssim']&.first
          end
        end

        result_map.compact
      end

      # Roll up all metrics for each monograph
      def roll_up_metrics(monograph_data)
        monograph_data.map do |monograph_noid, rows|
          {
            monograph_noid: monograph_noid,
            month: @month,
            year: @year,
            total_item_requests_month: rows.sum { |r| r[:total_item_requests_month] },
            total_item_requests_life: rows.sum { |r| r[:total_item_requests_life] },
            total_item_investigations_month: rows.sum { |r| r[:total_item_investigations_month] },
            total_item_investigations_life: rows.sum { |r| r[:total_item_investigations_life] },
            unique_item_requests_month: rows.sum { |r| r[:unique_item_requests_month] },
            unique_item_requests_life: rows.sum { |r| r[:unique_item_requests_life] },
            unique_item_investigations_month: rows.sum { |r| r[:unique_item_investigations_month] },
            unique_item_investigations_life: rows.sum { |r| r[:unique_item_investigations_life] }
          }
        end
      end
  end
end
