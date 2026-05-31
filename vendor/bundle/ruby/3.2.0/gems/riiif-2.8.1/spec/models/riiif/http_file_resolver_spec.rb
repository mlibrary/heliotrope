require 'spec_helper'

describe Riiif::HttpFileResolver do
  subject { described_class.new }

  before do
    Dir.glob('tmp/network_files/*') do |f|
      File.unlink(f)
    end
    subject.id_to_uri = ->(id) { id }
  end

  it "raises an error when the file isn't found" do
    expect(Kernel).to receive(:open).and_raise(OpenURI::HTTPError.new('failure', StringIO.new))
    begin
      subject.find('1234')
    rescue Riiif::ImageNotFoundError => e
    end
    expect(e).to be_a Riiif::ImageNotFoundError
    expect(e.message).to eq 'failure'
  end

  context 'when basic authentication credentials are set' do
    let(:credentials) { %w(username s0s3kr3t) }
    before do
      subject.basic_auth_credentials = credentials
    end

    it 'uses basic auth credentials' do
      expect(Kernel).to receive(:open).with('1234', http_basic_authentication: credentials)
      subject.find('1234')
    end
  end
end
