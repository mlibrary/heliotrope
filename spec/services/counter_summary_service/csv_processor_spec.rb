# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe CounterSummaryService::CsvProcessor do
  let(:year) { 2025 }
  let(:month) { 7 }
  let(:processor) { described_class.new(year, month) }
  let(:csv_path) { File.join(@spec_tmpdir, 'test_counter_stats.csv') }

  around do |example|
    spec_scratch_path = File.join(Settings.scratch_space_path, 'spec')
    FileUtils.mkdir_p(spec_scratch_path)

    Dir.mktmpdir('counter_summary_csv_processor_spec_', spec_scratch_path) do |tmpdir|
      @spec_tmpdir = tmpdir
      example.run
    end
  end

  before do
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
  end
  describe '#process_file' do
    context 'with valid CSV data' do
      let(:monograph_noid) { '00000011h' }
      let(:file_set_noid) { 'xp68kg513' }

      before do
        # Mock batch Solr query response
        allow(ActiveFedora::SolrService).to receive(:query).with(
          "{!terms f=id}#{monograph_noid},#{file_set_noid}",
          anything
        ).and_return([
          { 'id' => monograph_noid, 'has_model_ssim' => ['Monograph'] },
          { 'id' => file_set_noid, 'has_model_ssim' => ['FileSet'], 'monograph_id_ssim' => [monograph_noid] }
        ])

        # Create test CSV with actual column names from SIQ
        CSV.open(csv_path, 'w') do |csv|
          csv << ['Identifier', 'Total_Item_Requests (for the month)', 'Total_Item_Requests (life to date)',
                  'Total_Item_Investigations (for the month)', 'Total_Item_Investigations (life to date)',
                  'Unique_Item_Requests (for the month)', 'Unique_Item_Requests (life to date)',
                  'Unique_Item_Investigations (for the month)', 'Unique_Item_Investigations (life to date)']
          csv << [monograph_noid, '100', '2721', '150', '2722', '80', '2167', '120', '2168']
          csv << [file_set_noid, '50', '500', '75', '750', '40', '400', '60', '600']
        end
      end

      it 'processes the CSV and returns rolled-up stats' do
        results = processor.process_file(csv_path)
        expect(results).to be_an(Array)
        expect(results.length).to eq(1)

        stat = results.first
        expect(stat[:monograph_noid]).to eq(monograph_noid)
        expect(stat[:year]).to eq(year)
        expect(stat[:month]).to eq(month)
      end

      it 'rolls up metrics correctly' do
        results = processor.process_file(csv_path)
        stat = results.first

        # Should sum monograph + file_set metrics
        expect(stat[:total_item_requests_month]).to eq(150) # 100 + 50
        expect(stat[:total_item_requests_life]).to eq(3221) # 2721 + 500
        expect(stat[:total_item_investigations_month]).to eq(225) # 150 + 75
        expect(stat[:total_item_investigations_life]).to eq(3472) # 2722 + 750
      end
    end

    context 'with chapter identifiers' do
      let(:file_set_noid) { '00000011h' }
      let(:monograph_noid) { 'abc123xyz' }
      let(:chapter_id) { '00000011h.0007' }

      before do
        # Mock batch Solr query for file_set (chapter parent)
        allow(ActiveFedora::SolrService).to receive(:query).with(
          "{!terms f=id}#{file_set_noid}",
          anything
        ).and_return([{ 'id' => file_set_noid, 'has_model_ssim' => ['FileSet'], 'monograph_id_ssim' => [monograph_noid] }])

        CSV.open(csv_path, 'w') do |csv|
          csv << ['Identifier', 'Total_Item_Requests (for the month)', 'Total_Item_Requests (life to date)',
                  'Total_Item_Investigations (for the month)', 'Total_Item_Investigations (life to date)',
                  'Unique_Item_Requests (for the month)', 'Unique_Item_Requests (life to date)',
                  'Unique_Item_Investigations (for the month)', 'Unique_Item_Investigations (life to date)']
          csv << [chapter_id, '25', '125', '30', '130', '20', '115', '25', '120']
        end
      end

      it 'extracts parent noid from chapter identifier' do
        results = processor.process_file(csv_path)
        expect(results.length).to eq(1)
        expect(results.first[:monograph_noid]).to eq(monograph_noid)
      end

      it 'rolls up chapter metrics to monograph' do
        results = processor.process_file(csv_path)
        stat = results.first

        expect(stat[:total_item_requests_month]).to eq(25)
        expect(stat[:total_item_requests_life]).to eq(125)
      end
    end

    context 'with missing file' do
      it 'returns empty array' do
        results = processor.process_file('/nonexistent/path.csv')
        expect(results).to eq([])
      end
    end

    context 'with malformed CSV' do
      before do
        File.write(
          csv_path,
          <<~CSV
            Identifier,Total_Item_Requests (for the month),Total_Item_Requests (life to date),Total_Item_Investigations (for the month),Total_Item_Investigations (life to date),Unique_Item_Requests (for the month),Unique_Item_Requests (life to date),Unique_Item_Investigations (for the month),Unique_Item_Investigations (life to date)
            "bad_identifier,"10",100,15,150,8,80,12,120
          CSV
        )
      end

      it 'returns empty array and adds an error for malformed CSV' do
        results = processor.process_file(csv_path)
        expect(results).to eq([])
        expect(processor.errors).to include(a_string_matching(/CSV parsing error|parse/i))
      end
    end

    context 'with identifiers not found in Solr' do
      before do
        # Mock empty Solr response
        allow(ActiveFedora::SolrService).to receive(:query).and_return([])

        CSV.open(csv_path, 'w') do |csv|
          csv << ['Identifier', 'Total_Item_Requests (for the month)', 'Total_Item_Requests (life to date)',
                  'Total_Item_Investigations (for the month)', 'Total_Item_Investigations (life to date)',
                  'Unique_Item_Requests (for the month)', 'Unique_Item_Requests (life to date)',
                  'Unique_Item_Investigations (for the month)', 'Unique_Item_Investigations (life to date)']
          csv << ['invalid_noid', '10', '100', '15', '150', '8', '80', '12', '120']
        end
      end

      it 'logs errors for unknown identifiers' do
        results = processor.process_file(csv_path)
        expect(results).to be_empty
        expect(processor.errors).to include(/Could not find monograph for identifier: invalid_noid/)
      end
    end

    context 'with invalid CSV headers' do
      before do
        CSV.open(csv_path, 'w') do |csv|
          csv << ['WrongColumn', 'BadHeader', 'InvalidColumn']
          csv << ['test123', '100', '1000']
        end
      end

      it 'returns empty array' do
        results = processor.process_file(csv_path)
        expect(results).to be_empty
      end

      it 'logs header validation errors' do
        processor.process_file(csv_path)
        expect(processor.errors).to include(/CSV missing required columns/)
      end
    end

    context 'with partial CSV headers' do
      before do
        CSV.open(csv_path, 'w') do |csv|
          csv << ['Identifier', 'Total_Item_Requests (for the month)']  # Missing other required columns
          csv << ['test123', '100']
        end
      end

      it 'fails validation and returns empty array' do
        results = processor.process_file(csv_path)
        expect(results).to be_empty
        expect(processor.errors).to include(/CSV missing required columns/)
      end
    end
  end

  describe '#batch_find_monographs' do
    let(:monograph_noid) { 'monograph123' }
    let(:file_set_noid) { 'fileset456' }

    it 'returns monograph noid mapping for monograph identifiers' do
      allow(ActiveFedora::SolrService).to receive(:query).with(
        "{!terms f=id}#{monograph_noid}",
        anything
      ).and_return([{ 'id' => monograph_noid, 'has_model_ssim' => ['Monograph'] }])

      result = processor.send(:batch_find_monographs, [monograph_noid])
      expect(result[monograph_noid]).to eq(monograph_noid)
    end

    it 'returns parent monograph noid mapping for file_set identifiers' do
      allow(ActiveFedora::SolrService).to receive(:query).with(
        "{!terms f=id}#{file_set_noid}",
        anything
      ).and_return([{ 'id' => file_set_noid, 'has_model_ssim' => ['FileSet'], 'monograph_id_ssim' => [monograph_noid] }])

      result = processor.send(:batch_find_monographs, [file_set_noid])
      expect(result[file_set_noid]).to eq(monograph_noid)
    end

    it 'returns parent monograph noid mapping for chapter identifiers' do
      chapter_id = "#{file_set_noid}.0007"

      allow(ActiveFedora::SolrService).to receive(:query).with(
        "{!terms f=id}#{file_set_noid}",
        anything
      ).and_return([{ 'id' => file_set_noid, 'has_model_ssim' => ['FileSet'], 'monograph_id_ssim' => [monograph_noid] }])

      result = processor.send(:batch_find_monographs, [chapter_id])
      expect(result[chapter_id]).to eq(monograph_noid)
    end

    it 'handles multiple identifiers in a single batch' do
      allow(ActiveFedora::SolrService).to receive(:query).with(
        "{!terms f=id}#{monograph_noid},#{file_set_noid}",
        anything
      ).and_return([
        { 'id' => monograph_noid, 'has_model_ssim' => ['Monograph'] },
        { 'id' => file_set_noid, 'has_model_ssim' => ['FileSet'], 'monograph_id_ssim' => [monograph_noid] }
      ])

      result = processor.send(:batch_find_monographs, [monograph_noid, file_set_noid])
      expect(result[monograph_noid]).to eq(monograph_noid)
      expect(result[file_set_noid]).to eq(monograph_noid)
    end

    it 'returns empty hash for unknown identifiers' do
      allow(ActiveFedora::SolrService).to receive(:query).and_return([])

      result = processor.send(:batch_find_monographs, ['unknown'])
      expect(result).to be_empty
    end

    it 'handles Solr errors gracefully' do
      allow(ActiveFedora::SolrService).to receive(:query).and_raise(StandardError, 'Solr error')

      result = processor.send(:batch_find_monographs, [monograph_noid])
      expect(result).to be_empty
      expect(processor.errors).to include(/Batch Solr query error/)
    end
  end
end
