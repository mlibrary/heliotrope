# frozen_string_literal: true

# Customized authority to include marshaling behaviors
#
# The name is not perfect, but we have some work to do as far as migrating the
# Authority singleton methods. In practice, this instance will be registered in
# the services container, so its name is not relevant except in the services
# initializer.

class HeliotropeAuthority < Checkpoint::Authority
  include Skylight::Helpers

  instrument_method
  def licenses_for(actor, target)
    retries ||= 0
    Greensub::License.where(
      id: what(actor, target)
        .filter_map { |license| license.id if license.token.type.downcase == 'license' }
    )
  rescue  StandardError => e
    Rails.logger.error(%Q|HeliotropeAuthority.licenses_for RETRY #{retries}: #{e} #{e.backtrace.join("\n")}|)
    retries += 1
    retry if retries < 3
  end

  # This might be garbage -- not sure if we want generic marshaling
  def credentials_from(tokens)
    Array(tokens).map do |token|
      # TODO: Probably raise if we find a credential type we can't handle???
      # TODO: Deal with group query instead of looping
      case token.type.downcase
      when 'permission'
        Checkpoint::Permission.new(token.id)
      when 'license'
        # Greensub::License.find(token.id)
        License.find(token.id)
      end
    end
  end
end
