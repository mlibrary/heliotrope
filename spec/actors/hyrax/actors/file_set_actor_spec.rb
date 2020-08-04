# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Actors::FileSetActor do
  let(:user)          { create(:user) }
  let(:file_set)      { create(:file_set) }
  let(:actor)         { described_class.new(file_set, user) }

  describe '#create_metadata' do
    before do
      actor.create_metadata
    end

    # https://tools.lib.umich.edu/jira/browse/HELIO-2196
    it 'does not set creator to [user.user_key] where user is depositor' do
      expect(file_set.creator).to be_empty
      expect(file_set.depositor).not_to be_blank
      expect(file_set.creator.first).not_to eq(file_set.depositor)
    end
  end

  # Overriding this from Hyrax due to how tempfiles are handled in Versioning uploads
  # HELIO-3506
  describe "#update_content" do
    # rubocop:disable RSpec/MessageSpies
    let(:local_file)    { File.open(Rails.root.join("spec", "fixtures", "dummy.pdf")) }
    let(:relation)      { :original_file }
    let(:file_actor)    { Hyrax::Actors::FileActor.new(file_set, relation, user) }

    before do
      allow(CharacterizeJob).to receive_messages(perform_later: nil, perform_now: nil)
    end

    context "with a Hyrax::UploadedFile" do
      let(:file) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri.to_s, file: local_file) }

      it 'performs_later on the ingest_file and returns queued job' do
        expect(IngestJob).to receive(:perform_later).with(any_args).and_return(IngestJob.new)
        expect(actor.update_content(file)).to be_a(IngestJob)
      end
      it 'runs callbacks', perform_enqueued: [IngestJob] do
        # Do not bother ingesting the file -- test only the result of callback
        allow(file_actor).to receive(:ingest_file).with(any_args).and_return(double)
        expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)
        actor.update_content(local_file)
      end
    end

    context "with a ActionDispatch::HTTP::UploadedFile Tempfile (a Versioning upload)" do
      let(:file) { Rack::Test::UploadedFile.new(local_file.path, 'image/png') }

      it 'performs_now on the ingest_file and returns queued job' do
        expect(IngestJob).to receive(:perform_now).with(any_args).and_return(IngestJob.new)
        expect(actor.update_content(file)).to be_a(IngestJob)
      end
      it 'runs callbacks, but with perform_later', perform_enqueued: [IngestJob] do
        # Do not bother ingesting the file -- test only the result of callback
        allow(file_actor).to receive(:ingest_file).with(any_args).and_return(double)
        expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)
        actor.update_content(local_file)
      end
    end
  end
end
