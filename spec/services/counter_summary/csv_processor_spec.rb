# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterSummaryService::CsvProcessor do
  subject(:processor) { described_class.new }

  describe '#initialize' do
    it 'starts with empty errors' do
      expect(processor.errors).to eq([])
    end

    it 'creates a new instance successfully' do
      expect(processor).to be_a(described_class)
    end
  end

  describe '#process_file' do
    let(:tmpfile) { Tempfile.new(['test', '.csv']) }

    after { tmpfile.unlink }

    context 'with a valid CSV file' do
      before do
        tmpfile.write("title,doi,publisher\nBook One,10.3998/test.1,Publisher A\nBook Two,10.3998/test.2,Publisher B")
        tmpfile.close
      end

      it 'returns an array' do
        expect(processor.process_file(tmpfile.path)).to be_an(Array)
      end

      it 'returns the correct number of rows' do
        expect(processor.process_file(tmpfile.path).length).to eq(2)
      end

      it 'parses row data correctly' do
        result = processor.process_file(tmpfile.path)
        expect(result.first['title']).to eq('Book One')
      end

      it 'does not add any errors' do
        processor.process_file(tmpfile.path)
        expect(processor.errors).to be_empty
      end
    end

    context 'with an empty CSV file' do
      before do
        tmpfile.write('')
        tmpfile.close
      end

      it 'returns an empty array' do
        expect(processor.process_file(tmpfile.path)).to eq([])
      end

      it 'does not add any errors' do
        processor.process_file(tmpfile.path)
        expect(processor.errors).to be_empty
      end
    end

    context 'with a headers-only CSV file' do
      before do
        tmpfile.write("title,doi,publisher\n")
        tmpfile.close
      end

      it 'returns an empty array' do
        expect(processor.process_file(tmpfile.path)).to eq([])
      end

      it 'does not add any errors' do
        processor.process_file(tmpfile.path)
        expect(processor.errors).to be_empty
      end
    end

    context 'with a single row CSV file' do
      before do
        tmpfile.write("title,doi\nSingle Book,10.3998/test.1\n")
        tmpfile.close
      end

      it 'returns one row' do
        expect(processor.process_file(tmpfile.path).length).to eq(1)
      end

      it 'parses the row correctly' do
        result = processor.process_file(tmpfile.path)
        expect(result.first['doi']).to eq('10.3998/test.1')
      end
    end

    context 'with malformed CSV' do
      before do
        tmpfile.write("title,doi\n\"bad\"field,10.3998/test.1\n")
        tmpfile.close
      end

      it 'returns empty array and logs parsing errors' do
        result = processor.process_file(tmpfile.path)
        expect(result).to eq([])
        expect(processor.errors).to include(a_string_matching(/Malformed CSV|CSV parsing error/i))
      end

      it 'adds exactly one error' do
        processor.process_file(tmpfile.path)
        expect(processor.errors.length).to eq(1)
      end
    end

    context 'when file does not exist' do
      it 'returns empty array' do
        expect(processor.process_file('/nonexistent/path/to/file.csv')).to eq([])
      end

      it 'logs an error' do
        processor.process_file('/nonexistent/path/to/file.csv')
        expect(processor.errors).not_to be_empty
      end
    end
  end
end
