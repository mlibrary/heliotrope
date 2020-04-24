# frozen_string_literal: true

require 'rails_helper'

describe 'Routes', type: :routing do
  describe 'publish' do
    it 'publishes the monograph' do
      expect(post: '/concerns/monographs/77/publish').to route_to(controller: 'hyrax/monographs', id: '77', action: 'publish')
    end
  end

  describe 'for Presses' do
    it 'has user roles within the press' do
      expect(get: 'umich/users').to route_to(controller: 'roles', action: 'index', press_id: 'umich')
    end

    it 'has a press catalog' do
      expect(get: '/umich').to route_to(controller: 'press_catalog', action: 'index', press: 'umich')
    end
  end

  describe 'Monograph Catalog' do
    it { expect(get: 'concern/monographs/new').to route_to(controller: 'hyrax/monographs', action: 'new') }
  end

  describe 'Score Catalog' do
    it { expect(get: 'concern/scores/12').to route_to(controller: 'score_catalog', action: 'index', id: '12') }
  end
end
