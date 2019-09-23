# frozen_string_literal: true

# First in line after Hyrax::Actors::OptimisticLockValidator (see: config/initializers/hyrax_actor_factory.rb)
class HeliotropeActor < Hyrax::Actors::AbstractActor
  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if create was successful
  def create(env)
    heliotrope_actor(:before, :create, env) && next_actor.create(env) && heliotrope_actor(:after, :create, env)
  end

  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if update was successful
  def update(env)
    heliotrope_actor(:before, :update, env) && next_actor.update(env) && heliotrope_actor(:after, :update, env)
  end

  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if destroy was successful
  def destroy(env)
    heliotrope_actor(:before, :destroy, env) && next_actor.destroy(env) && heliotrope_actor(:after, :destroy, env)
  end

  private

    # :heliotrope_actor callback define in config/initializers/hyrax_callbacks.rb
    def heliotrope_actor(temporal, action, env)
      Hyrax.config.callback.run(:heliotrope_actor, temporal, action, env.curation_concern, env.user) if temporal == :before
      Rails.logger.info "heliotrope actor #{temporal} #{action} #{env.attributes}"
      Hyrax.config.callback.run(:heliotrope_actor, temporal, action, env.curation_concern, env.user) if temporal == :after
      true
    end
end
