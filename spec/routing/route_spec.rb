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
      expect(get: '/umich').to route_to(controller: 'press_catalog', action: 'index', subdomain: 'umich')
    end
  end

  describe 'for robots.txt' do
    it 'has robots.txt' do
      expect(get: '/robots.txt').to route_to(controller: 'robots', action: 'robots')
    end
  end

  describe 'Monograph Catalog' do
    it { expect(get: 'concern/monographs/new').to route_to(controller: 'hyrax/monographs', action: 'new') }
  end

  describe 'for Users' do
    it { expect(get: '/users').to route_to(controller: 'users', action: 'index') }
    it { expect(get: '/users/id').to route_to(controller: 'users', action: 'show', id: 'id') }
  end

  describe 'for Roles' do
    it { expect(get: '/roles').to route_to(controller: 'roles', action: 'index2') }
    it { expect(get: '/roles/id').to route_to(controller: 'roles', action: 'show', id: 'id') }
  end

  describe 'for production (and test)' do
    # temporarily disable devise registrations in production #266
    it 'has no password routes' do
      expect(get: '/users/password/new').not_to be_routable
      expect(get: '/users/password').to route_to(controller: 'users', action: 'show', id: 'password')
    end
    it 'has no registation routes' do
      expect(get: '/users/sign_up').to route_to(controller: 'users', action: 'show', id: 'sign_up')
    end
  end
end
