# frozen_string_literal: true

class ModelTreeActor < Hyrax::Actors::AbstractActor
  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if create was successful
  # def create(env)
  #   next_actor.create(env)
  # end

  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if update was successful
  # def update(env)
  #   next_actor.update(env)
  # end

  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if destroy was successful
  def destroy(env)
    begin
      ModelTreeService.new.unlink(env.curation_concern.id)
    rescue StandardError => e
      Rails.logger.error("ERROR: ModelTreeActor.destroy(#{env}) error #{e}")
    end

    next_actor.destroy(env)
  end
end
