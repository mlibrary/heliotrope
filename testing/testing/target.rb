# frozen_string_literal: true

require_relative '../../app/services/turnsole/service'

module Testing
  module Target
    class << self
      def url
        Testing.config.target_url
      end

      def testing_press_cleaner
        monographs = testing_press_monographs
        monographs.each do |monograph|
          turnsole.delete_monograph(monograph['id'])
        end
      end

      def testing_press_monographs
        testing_press_id = turnsole.find_press('testing')
        turnsole.press_monographs(testing_press_id)
      end

      private
        def turnsole
          @turnsole ||= Turnsole::Service.new(Testing.config.target_token, Testing.config.target_url + 'api/')
        end
    end
  end
end
