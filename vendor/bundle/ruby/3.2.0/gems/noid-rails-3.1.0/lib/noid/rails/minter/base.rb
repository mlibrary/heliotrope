# frozen_string_literal: true

require 'noid'

module Noid
  module Rails
    module Minter
      # @abstract the base class for minters
      class Base < ::Noid::Minter
        ##
        # @param template [#to_s] a NOID template
        # @see Noid::Template
        def initialize(template = default_template)
          super(template: template.to_s)
        end

        ##
        # Sychronously mint a new identifier.
        #
        # @return [String] the minted identifier
        def mint
          Mutex.new.synchronize do
            loop do
              pid = next_id
              return pid unless identifier_in_use?(pid)
            end
          end
        end

        ##
        # @return [Hash{Symbol => String, Object}] representation of the current minter state
        def read
          raise NotImplementedError, 'Implement #read in child class'
        end

        ##
        # Updates the minter state to that of the `minter` parameter.
        #
        # @param minter [Minter::Base]
        # @return [void]
        def write!(_)
          raise NotImplementedError, 'Implement #write! in child class'
        end

        private

        def identifier_in_use?(id)
          Noid::Rails.config.identifier_in_use.call(id)
        end

        ##
        # @return [#to_s] the default template for this
        def default_template
          Noid::Rails.config.template
        end

        ##
        # @return [String] a new identifier
        def next_id
          raise NotImplementedError, 'Implement #next_id in child class'
        end
      end
    end
  end
end
