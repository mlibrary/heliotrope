# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExtractIngestJob, type: :job do
  let(:job) { described_class.new }
  let(:source) { '123456789' }
  let(:service) { instance_double(Turnsole::Service) }
  let(:importer) { instance_double(Import::Importer, run: nil) }
  let(:archive) do
    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry('manifest.csv')
      zip.write('Monograph manifest')
    end.string
  end

  around do |example|
    Dir.mktmpdir do |directory|
      @extract_path = directory
      example.run
    end
  end

  before do
    allow(job).to receive(:extract_path).and_return(@extract_path)
    allow(Press).to receive(:where).with(subdomain: 'michigan').and_return([instance_double(Press)])
    allow(Turnsole::Service).to receive(:new).with('token', 'base').and_return(service)
    allow(service).to receive(:monograph_extract).with(source).and_return(archive)
    allow(Import::Importer).to receive(:new).with(root_dir: File.join(@extract_path, source), press: 'michigan').and_return(importer)
  end

  it 'extracts the downloaded archive into the import directory before running the importer' do
    expect(importer).to receive(:run) do
      expect(File.read(File.join(@extract_path, source, 'manifest.csv'))).to eq 'Monograph manifest'
    end

    job.perform('token', 'base', source, 'michigan')

    expect(File).not_to exist(File.join(@extract_path, "#{source}.zip"))
  end
end
