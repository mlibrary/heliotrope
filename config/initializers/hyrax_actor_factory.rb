# frozen_string_literal: true

# In hyrax this is app/services/default_middleware_stack.rb

# module Hyrax
#   class DefaultMiddlewareStack
#     def self.build_stack
#       ActionDispatch::MiddlewareStack.new.tap do |middleware|
#         middleware.use Hyrax::Actors::TransactionalRequest
#         middleware.use Hyrax::Actors::OptimisticLockValidator
#         middleware.use Hyrax::Actors::CreateWithRemoteFilesActor
#         middleware.use Hyrax::Actors::CreateWithFilesActor
#         middleware.use Hyrax::Actors::CollectionsMembershipActor
#         middleware.use Hyrax::Actors::AddToWorkActor
#         middleware.use Hyrax::Actors::AssignRepresentativeActor
#         middleware.use Hyrax::Actors::AttachMembersActor
#         middleware.use Hyrax::Actors::ApplyOrderActor
#         middleware.use Hyrax::Actors::InterpretVisibilityActor
#         middleware.use Hyrax::Actors::TransferRequestActor
#         middleware.use Hyrax::Actors::DefaultAdminSetActor
#         middleware.use Hyrax::Actors::ApplyPermissionTemplateActor
#         middleware.use Hyrax::Actors::CleanupFileSetsActor
#         middleware.use Hyrax::Actors::CleanupTrophiesActor
#         middleware.use Hyrax::Actors::FeaturedWorkActor
#         middleware.use Hyrax::Actors::ModelActor
#         middleware.use Hyrax::Actors::InitializeWorkflowActor
#       end
#     end
#   end
# end

# Insert actor after obtaining lock so we are first in line!
Hyrax::CurationConcern.actor_factory.insert_after(Hyrax::Actors::OptimisticLockValidator, CreateWithImportFilesActor)
Hyrax::CurationConcern.actor_factory.insert_after(Hyrax::Actors::OptimisticLockValidator, HeliotropeActor)
# Destroy FeaturedRepresentatives on delete
Hyrax::CurationConcern.actor_factory.insert_after(Hyrax::Actors::CleanupTrophiesActor, FeaturedRepresentativeActor)

# NOTE: New call order is:
# ...
# middleware.use Hyrax::Actors::OptimisticLockValidator
# middleware.use HeliotropeActor
# middleware.use CreateWithImportFilesActor
# middleware.use Hyrax::Actors::CreateWithRemoteFilesActor
# ...
