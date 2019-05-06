# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttachImportFilesToWorkJob do
  subject { described_class.perform_now(monograph, monograph_attributes, files, files_attributes) }

  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:monograph) { create(:monograph, user: user, visibility: visibility) }
  let(:monograph_attributes) { { visibility: visibility } }
  let(:files) { [] }
  let(:files_attributes) { [] }
  let(:n) { 0 }

  before do
    stub_out_redis # Travis CI can't handle jobs
    n.times do |i|
      files << build(:uploaded_file, file: File.open(fixture_path + '/present.txt'))
      files_attributes << { title: ["title#{i}"] }
    end
  end

  shared_examples 'a file attacher' do
    it 'attaches files, copies visibility and permissions and updates the uploaded files' do
      expect(JobIoWrapper).to receive(:create_with_varied_file_handling!).exactly(n).times
      expect(IngestJob).to receive(:perform_later).exactly(n).times
      subject
      monograph.reload
      expect(monograph.visibility).to eq monograph_attributes[:visibility]
      expect(monograph.file_sets.count).to eq n
      expect(monograph.file_sets.map(&:visibility)).to all(eq monograph.visibility)
      expect(monograph.ordered_members.to_a.map(&:uri).map(&:to_s)).to eq files.map(&:file_set_uri)
      expect(monograph.representative_id).to be_nil
      expect(monograph.thumbnail_id).to be_nil
    end
  end

  context 'when files is empty' do
    let(:n) { 0 }

    it_behaves_like 'a file attacher'
  end

  context 'when files exist, which they always do (see importer)' do
    let(:n) { 3 }

    it_behaves_like 'a file attacher'
  end

  context 'when files exist and when they do not a.k.a. external resources' do
    let(:n) { 4 }

    before do
      files[1] = build(:uploaded_file, file: File.open('/dev/null'))
      files[3] = build(:uploaded_file, file: File.open(fixture_path + '/empty.txt'))
    end

    it_behaves_like 'a file attacher'
  end
end

# Example spec from Hyrax
#
# RSpec.describe AttachFilesToWorkJob do
#   context "happy path" do
#     let(:file1) { File.open(fixture_path + '/world.png') }
#     let(:file2) { File.open(fixture_path + '/image.jp2') }
#     let(:uploaded_file1) { build(:uploaded_file, file: file1) }
#     let(:uploaded_file2) { build(:uploaded_file, file: file2) }
#     let(:generic_work) { create(:public_generic_work) }
#
#     shared_examples 'a file attacher' do
#       it 'attaches files, copies visibility and permissions and updates the uploaded files' do
#         expect(ImportUrlJob).not_to receive(:perform_later)
#         expect(CharacterizeJob).to receive(:perform_later).twice
#         described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
#         generic_work.reload
#         expect(generic_work.file_sets.count).to eq 2
#         expect(generic_work.file_sets.map(&:visibility)).to all(eq 'open')
#         expect(uploaded_file1.reload.file_set_uri).not_to be_nil
#       end
#     end
#
#     context "with uploaded files on the filesystem" do
#       before do
#         generic_work.permissions.build(name: 'userz@bbb.ddd', type: 'person', access: 'edit')
#         generic_work.save
#       end
#       it_behaves_like 'a file attacher' do
#         it 'records the depositor(s) in edit_users' do
#           expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor, 'userz@bbb.ddd']))
#         end
#       end
#     end
#
#     context "with uploaded files at remote URLs" do
#       let(:url1) { 'https://example.com/my/img.png' }
#       let(:url2) { URI('https://example.com/other/img.png') }
#       let(:fog_file1) { double(CarrierWave::Storage::Abstract, url: url1) }
#       let(:fog_file2) { double(CarrierWave::Storage::Abstract, url: url2) }
#
#       before do
#         allow(uploaded_file1.file).to receive(:file).and_return(fog_file1)
#         allow(uploaded_file2.file).to receive(:file).and_return(fog_file2)
#       end
#
#       it_behaves_like 'a file attacher'
#     end
#   end
# end
