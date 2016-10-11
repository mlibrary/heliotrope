class MinterState < ActiveRecord::Base
  validates :namespace, presence: true, uniqueness: true
  validates :template, presence: true
  validates :template, format: { with: Object.const_get('Noid::Template::VALID_PATTERN'), message: 'value fails regex' }

  # @return [Hash] options for Noid::Minter.new
  # * template [String] setting the identifier pattern
  # * seq [Integer] reflecting minter position in sequence
  # * counters [Array{Hash}] "buckets" each with :current and :max values
  # * rand [Object] random number generator object
  def noid_options
    Rails.logger.debug("
    app/model/minter_state.rb is a placeholder for active_fedora-noid-2.0.0.beta1/app/models/minter_state.rb
    See: https://github.com/projecthydra-labs/active_fedora-noid/issues/29
    Once active_fedora-noid-2.0.0 is out of beta, and CurationConcerns no longer requires it,
    remove this file.
    (This isn't actually used by heliotrope at all, it's just here to stop an initialization error in production)
    See #292
    ")
    return nil unless template
    opts = {
      template: template,
      seq: seq
    }
    opts[:counters] = JSON.parse(counters, symbolize_names: true) if counters
    opts[:rand]     = Marshal.load(random) if random
    opts
  end
end
