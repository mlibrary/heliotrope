# frozen_string_literal: true
RSpec.shared_examples 'a Valkyrie::StorageAdapter::File' do
  before do
    raise 'adapter must be set with `let(:file)`' unless defined? file
  end

  subject { file }

  it { is_expected.to respond_to(:read) }
  it { is_expected.to respond_to(:rewind) }
  it { is_expected.to respond_to(:id) }
  it { is_expected.to respond_to(:close) }
  describe "#disk_path" do
    it "returns an existing disk path" do
      expect(File.exist?(file.disk_path)).to eq true
    end
  end
end
