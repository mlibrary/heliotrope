# frozen_string_literal: true

require 'noid'

module Noid
  module Rails
    module Minter
      # A minter backed by a database table. You would select this if you
      # need to mint identifers on several distributed front-ends that do not
      # share a common file system.
      class Db < Base
        def read
          deserialize(instance)
        end

        def write!(minter)
          serialize(instance, minter)
        end

        protected

        # @param [MinterState] inst minter state to be converted
        # @return [Hash{Symbol => String, Object}] minter state as a Hash, like #read
        # @see #read, Noid::Rails::Minter::Base#read
        def deserialize(inst)
          filtered_hash = inst.as_json.slice('template', 'counters', 'seq', 'rand', 'namespace')
          if filtered_hash['counters']
            filtered_hash['counters'] = JSON.parse(filtered_hash['counters'],
                                                   symbolize_names: true)
          end
          filtered_hash.symbolize_keys
        end

        # @param [MinterState] inst a locked row/object to be updated
        # @param [::Noid::Minter] minter state containing the updates
        def serialize(inst, minter)
          # namespace and template are the same, now update the other attributes
          inst.update!(
            seq: minter.seq,
            counters: JSON.generate(minter.counters),
            rand: Marshal.dump(minter.instance_variable_get(:@rand))
          )
        end

        # Uses pessimistic lock to ensure the record fetched is the same one updated.
        # Should be fast enough to avoid terrible deadlock.
        # Must lock because of multi-connection context! (transaction is per connection -- not enough)
        # The DB table will only ever have at most one row per namespace.
        # The 'default' namespace row is inserted by `rails generate noid:rails:seed`
        # or autofilled by instance below.
        # If you want another namespace, edit your config initialzer to something like:
        #     Noid::Rails.config.namespace = 'druid'
        #     Noid::Rails.config.template = '.reeedek'
        # and in your app run:
        #     bundle exec rails generate noid:rails:seed
        def next_id
          id = nil
          MinterState.transaction do
            locked = instance
            minter = ::Noid::Minter.new(deserialize(locked))
            id = minter.mint
            serialize(locked, minter)
          end
          id
        end

        # @return [MinterState]
        def instance
          MinterState.lock.find_by!(
            namespace: Noid::Rails.config.namespace,
            template: Noid::Rails.config.template
          )
        rescue ActiveRecord::RecordNotFound
          MinterState.seed!(
            namespace: Noid::Rails.config.namespace,
            template: Noid::Rails.config.template
          )
        end
      end
    end
  end
end
