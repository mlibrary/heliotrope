# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CurationConcern do
  subject(:actor_factory) { described_class.actor_factory }

  describe 'middlewares' do
    subject(:middlewares) { actor_factory.middlewares }

    it do
      expect(middlewares.count).to eq 20
      expect(middlewares[0]).to eq Hyrax::Actors::TransactionalRequest
      expect(middlewares[1]).to eq Hyrax::Actors::OptimisticLockValidator
      expect(middlewares[2]).to eq HeliotropeActor
      expect(middlewares[3]).to eq CreateWithImportFilesActor
      expect(middlewares[4]).to eq Hyrax::Actors::CreateWithRemoteFilesActor
      expect(middlewares[5]).to eq Hyrax::Actors::CreateWithFilesActor
      expect(middlewares[6]).to eq Hyrax::Actors::CollectionsMembershipActor
      expect(middlewares[7]).to eq Hyrax::Actors::AddToWorkActor
      expect(middlewares[8]).to eq Hyrax::Actors::AttachMembersActor
      expect(middlewares[9]).to eq Hyrax::Actors::ApplyOrderActor
      expect(middlewares[10]).to eq Hyrax::Actors::InterpretVisibilityActor
      expect(middlewares[11]).to eq Hyrax::Actors::TransferRequestActor
      expect(middlewares[12]).to eq Hyrax::Actors::DefaultAdminSetActor
      expect(middlewares[13]).to eq Hyrax::Actors::ApplyPermissionTemplateActor
      expect(middlewares[14]).to eq Hyrax::Actors::CleanupFileSetsActor
      expect(middlewares[15]).to eq Hyrax::Actors::CleanupTrophiesActor
      expect(middlewares[16]).to eq FeaturedRepresentativeActor
      expect(middlewares[17]).to eq Hyrax::Actors::FeaturedWorkActor
      expect(middlewares[18]).to eq Hyrax::Actors::ModelActor
      expect(middlewares[19]).to eq Hyrax::Actors::InitializeWorkflowActor
      expect(middlewares[20]).to be nil
    end
  end
end
