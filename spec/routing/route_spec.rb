require 'rails_helper'

describe 'Routes', type: :routing do
  describe 'publish' do
    it 'publishes the monograph' do
      expect(post: '/concerns/monographs/77/publish').to route_to(controller: 'curation_concerns/monographs', id: '77', action: 'publish')
    end
  end

  describe 'for Presses' do
    it 'has user roles within the press' do
      expect(get: 'umich/users').to route_to(controller: 'roles', action: 'index', press_id: 'umich')
    end

    it 'has a press catalog' do
      expect(get: '/umich').to route_to(controller: 'press_catalog', action: 'index', subdomain: 'umich')
    end
  end
end
