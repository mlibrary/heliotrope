# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateWithImportFilesActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:monograph) { create(:monograph, user: user) }
  let(:env) { Hyrax::Actors::Environment.new(monograph, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:cover) { double("cover") }
  let(:cover_metadata) { { title: ['cover'] } }
  let(:file1) { double("file1") }
  let(:file1_metadata) { { title: ['file1'] } }
  let(:file2) { double("file2") }
  let(:file2_metadata) { { title: ['file2'] } }
  let(:attributes) { { files: [cover, file1, file2], files_metadata: [cover_metadata, file1_metadata, file2_metadata] } }

  before do
    stub_out_redis # Travis CI can't handle jobs
    allow(File).to receive(:new).with(anything) do |value|
      value
    end
    allow(cover).to receive(:to_path).and_return('cover')
    allow(file1).to receive(:to_path).and_return('file1') if file1.present?
    allow(file2).to receive(:to_path).and_return('file2')
  end

  %i[create update].each do |mode|
    context "on #{mode}" do
      before do
        allow(terminator).to receive(mode).and_return(true)
      end

      context 'when files exist, which they always do (see importer)' do
        it 'is successful' do
          expect(JobIoWrapper).to receive(:create_with_varied_file_handling!).exactly(3).times
          expect(IngestJob).to receive(:perform_later).exactly(3).times
          middleware.public_send(mode, env)
          expect(monograph.representative_id).to eq monograph.ordered_members.to_a.first.id
          expect(monograph.thumbnail_id).to eq monograph.ordered_members.to_a.first.id
        end
      end

      context 'when files exist and when they do not a.k.a. external resources' do
        let(:file1) { '' } # empty string means an external resource

        it 'is successful' do
          expect(JobIoWrapper).to receive(:create_with_varied_file_handling!).exactly(2).times
          expect(IngestJob).to receive(:perform_later).exactly(2).times
          middleware.public_send(mode, env)
          expect(monograph.representative_id).to eq monograph.ordered_members.to_a.first.id
          expect(monograph.thumbnail_id).to eq monograph.ordered_members.to_a.first.id
        end
      end

      context 'when files is empty' do
        let(:attributes) { { files: [], files_metadata: [] } }

        it 'is successful' do
          expect(JobIoWrapper).to receive(:create_with_varied_file_handling!).exactly(0).times
          expect(IngestJob).to receive(:perform_later).exactly(0).times
          middleware.public_send(mode, env)
          expect(monograph.representative_id).to be nil
          expect(monograph.thumbnail_id).to be nil
        end
      end
    end
  end
end
