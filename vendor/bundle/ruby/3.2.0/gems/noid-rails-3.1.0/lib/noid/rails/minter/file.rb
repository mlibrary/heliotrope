# frozen_string_literal: true

require 'noid'

module Noid
  module Rails
    module Minter
      # A file based minter. This is a simple case.
      class File < Base
        attr_reader :statefile

        def initialize(template = default_template, statefile = default_statefile)
          @statefile = statefile
          super(template)
        end

        def default_statefile
          Noid::Rails.config.statefile
        end

        def read
          with_file do |f|
            state_for(f)
          end
        end

        def write!(minter)
          with_file do |f|
            # Wipe prior contents so the new state can be written from the beginning of the file
            f.truncate(0)
            f.write(Marshal.dump(minter.dump))
          end
        end

        protected

        def with_file
          ::File.open(statefile, 'a+b', 0o644) do |f|
            f.flock(::File::LOCK_EX)
            # Files opened in append mode seek to end of file
            f.rewind
            yield f
          end
        end

        # rubocop:disable Security/MarshalLoad
        def state_for(io_object)
          Marshal.load(io_object.read)
        rescue TypeError, ArgumentError
          { template: template }
        end
        # rubocop:enable Security/MarshalLoad

        def next_id
          state = read
          state[:template] &&= state[:template].to_s
          minter = ::Noid::Minter.new(state) # minter w/in the minter, lives only for an instant
          id = minter.mint
          write!(minter)
          id
        end
      end
    end
  end
end
