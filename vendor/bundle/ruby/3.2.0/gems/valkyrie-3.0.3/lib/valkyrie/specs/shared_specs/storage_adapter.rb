# frozen_string_literal: true
RSpec.shared_examples 'a Valkyrie::StorageAdapter' do
  before do
    raise 'storage_adapter must be set with `let(:storage_adapter)`' unless
      defined? storage_adapter
    raise 'file must be set with `let(:file)`' unless
      defined? file
    class Valkyrie::Specs::CustomResource < Valkyrie::Resource
    end
  end
  after do
    Valkyrie::Specs.send(:remove_const, :CustomResource)
  end
  subject { storage_adapter }
  it { is_expected.to respond_to(:handles?).with_keywords(:id) }
  it { is_expected.to respond_to(:find_by).with_keywords(:id) }
  it { is_expected.to respond_to(:delete).with_keywords(:id) }
  it { is_expected.to respond_to(:upload).with_keywords(:file, :resource, :original_filename) }

  it "can upload a file which is just an IO" do
    io_file = Tempfile.new('temp_io')
    io_file.write "Stuff"
    io_file.rewind
    sha1 = Digest::SHA1.file(io_file).to_s

    resource = Valkyrie::Specs::CustomResource.new(id: SecureRandom.uuid)

    expect(uploaded_file = storage_adapter.upload(file: io_file, original_filename: 'foo.jpg', resource: resource, fake_upload_argument: true)).to be_kind_of Valkyrie::StorageAdapter::File

    expect(uploaded_file.valid?(digests: { sha1: sha1 })).to be true
  end

  it "doesn't leave a file handle open on upload/find_by" do
    # No file handle left open from upload.
    resource = Valkyrie::Specs::CustomResource.new(id: "testdiscovery")
    pre_open_files = open_files
    uploaded_file = storage_adapter.upload(file: file, original_filename: 'foo.jpg', resource: resource, fake_upload_argument: true)
    file.close
    expect(pre_open_files.size).to eq open_files.size

    # No file handle left open from find_by
    pre_open_files = open_files
    the_file = storage_adapter.find_by(id: uploaded_file.id)
    expect(the_file).to be_kind_of Valkyrie::StorageAdapter::File
    expect(pre_open_files.size).to eq open_files.size
  end

  def open_files
    `lsof +D .`.split("\n").map { |r| r.split("\t").last }
  end

  it "can upload, validate, re-fetch, and delete a file" do
    resource = Valkyrie::Specs::CustomResource.new(id: "test")
    sha1 = Digest::SHA1.file(file).to_s
    size = file.size
    expect(uploaded_file = storage_adapter.upload(file: file, original_filename: 'foo.jpg', resource: resource, fake_upload_argument: true)).to be_kind_of Valkyrie::StorageAdapter::File

    expect(uploaded_file).to respond_to(:checksum).with_keywords(:digests)
    expect(uploaded_file).to respond_to(:valid?).with_keywords(:size, :digests)
    expect(uploaded_file.checksum(digests: [Digest::SHA1.new])).to eq([sha1])
    expect(uploaded_file.valid?(digests: { sha1: sha1 })).to be true
    expect(uploaded_file.valid?(size: size, digests: { sha1: sha1 })).to be true
    expect(uploaded_file.valid?(size: (size + 1), digests: { sha1: sha1 })).to be false
    expect(uploaded_file.valid?(size: size, digests: { sha1: 'bogus' })).to be false

    expect(storage_adapter.handles?(id: uploaded_file.id)).to eq true
    file = storage_adapter.find_by(id: uploaded_file.id)
    expect(file.id).to eq uploaded_file.id
    expect(file).to respond_to(:stream).with(0).arguments
    expect(file).to respond_to(:read).with(0).arguments
    expect(file).to respond_to(:rewind).with(0).arguments
    expect(file.stream).to respond_to(:read)
    new_file = Tempfile.new
    expect { IO.copy_stream(file, new_file) }.not_to raise_error

    storage_adapter.delete(id: uploaded_file.id)
    expect { storage_adapter.find_by(id: uploaded_file.id) }.to raise_error Valkyrie::StorageAdapter::FileNotFound
    expect { storage_adapter.find_by(id: Valkyrie::ID.new("noexist")) }.to raise_error Valkyrie::StorageAdapter::FileNotFound
  end
end
