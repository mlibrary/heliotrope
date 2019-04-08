# frozen_string_literal: true

require_relative '../../app/services/turnsole/service'

module Testing
  module Source
    class << self
      def url
        Testing.config.source_url
      end

      private

        def turnsole
          @turnsole ||= Turnsole::Service.new(Testing.config.source_token, Testing.config.source_url + 'api/')
        end
    end
  end
end
