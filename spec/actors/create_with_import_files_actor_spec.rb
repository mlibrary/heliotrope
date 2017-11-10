# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateWithImportFilesActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:monograph) { create(:monograph, user: user) }
  let(:import_uploaded_files_ids)  { [] }
  let(:import_uploaded_files) { [] }
  let(:import_uploaded_files_attributes) { [] }
  let(:attributes) { { import_uploaded_files_ids: import_uploaded_files_ids, import_uploaded_files_attributes: import_uploaded_files_attributes } }
  let(:env) { Hyrax::Actors::Environment.new(monograph, ability, attributes) }
  let(:expected_env) { Hyrax::Actors::Environment.new(monograph, ability, {}) }
  let(:n) { 0 }

  before do
    n.times do |i|
      import_uploaded_files_ids << i
      import_uploaded_files << "file#{i}"
      import_uploaded_files_attributes << { title: ["title#{i}"] }
    end
  end

  %i[create update].each do |mode|
    context "on #{mode}" do
      before do
        allow(terminator).to receive(mode).and_return(true)
        allow(Hyrax::UploadedFile).to receive(:find).with(import_uploaded_files_ids).and_return(import_uploaded_files)
      end

      context 'when files is empty' do
        let(:n) { 0 }
        it 'is successful' do
          expect(AttachImportFilesToWorkJob).not_to receive(:perform_later)
          middleware.public_send(mode, env)
        end
      end

      context 'when files exist' do
        let(:n) { 3 }
        it 'is successful' do
          expect(AttachImportFilesToWorkJob).to receive(:perform_later).with(expected_env.curation_concern, expected_env.attributes.to_h.symbolize_keys, import_uploaded_files, import_uploaded_files_attributes)
          middleware.public_send(mode, env)
        end
      end
    end
  end
end
