require 'rails_helper'

describe 'Routes', type: :routing do
  describe 'publish' do
    it 'publishes the monograph' do
      expect(post: '/concerns/monographs/77/publish').to route_to(controller: 'curation_concerns/monographs', id: '77', action: 'publish')
    end
  end
end
