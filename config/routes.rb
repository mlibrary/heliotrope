# frozen_string_literal: true

resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  current_user.present? && current_user.respond_to?(:platform_admin?) && current_user.platform_admin?
end

Rails.application.routes.draw do
  get 'epub/:id', controller: :e_pub, action: :show, as: :epub
  get 'epub/:id/*file', controller: :e_pub, action: :file, as: :epub_file
  get 'embed', controller: :embed, action: :show
  get 'fulcrum', controller: :fulcrum, action: :index, as: :fulcrum
  get 'fulcrum/:partial', controller: :fulcrum, action: :show, as: :partial_fulcrum

  mount Blacklight::Engine => '/'
  mount Riiif::Engine => '/image-service', as: 'riiif'

  constraints resque_web_constraint do
    mount ResqueWeb::Engine => "/resque"
  end

  # For anyone who doesn't meet resque_web_constraint,
  # fall through to this controller.
  get 'resque', controller: :jobs, action: :forbid

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  if Rails.env.eql?('development')
    devise_for :users
  else
    # temporarily disable devise registrations and password resets for production #266
    devise_for :users, skip: %i[registration password]
  end
  get 'users', controller: :users, action: :index, as: :users
  get 'users/:id', controller: :users, action: :show, as: :user
  get 'roles', controller: :roles, action: :index2, as: :roles
  get 'roles/:id', controller: :roles, action: :show, as: :role

  get '/', to: redirect('/index.html')

  mount Hyrax::Engine, at: '/'

  get 'concern/monographs/new', controller: 'hyrax/monographs', action: :new
  get 'concern/monographs/:id', controller: :monograph_catalog, action: :index, as: :monograph_catalog
  get 'concern/monographs/:id/show', controller: 'hyrax/monographs', action: :show, as: :monograph_show
  get 'monograph_catalog/facet/:id', controller: :monograph_catalog, action: :facet, as: :monograph_catalog_facet

  curation_concerns_basic_routes
  curation_concerns_embargo_management
  concern :exportable, Blacklight::Routes::Exportable.new

  namespace :hyrax, path: '/concerns' do
    resources :monographs, only: [] do
      member do
        post :publish
      end
    end
  end

  mount Qa::Engine => '/authorities'

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  get '/robots.txt' => 'robots#robots'

  resources :presses, only: %i[new create edit update]
  get '/presses' => 'presses#index'

  get '/:subdomain', controller: :press_catalog, action: :index, as: :press_catalog
  get '/:subdomain/facet', controller: :press_catalog, action: :facet

  resources :presses, path: '/', only: %i[index edit] do
    resources :sub_brands, only: %i[new create show edit update]

    resources :roles, path: 'users', only: %i[index create destroy] do
      collection do
        patch :update_all
      end
    end
  end

  # TODO: Used in dev only? If apache is in front I don't think this ever happens?
  # Might fix #379 but need to check
  get '/favicon/favicon.ico', to: redirect('/favicon.ico')

  root 'presses#index'
end
