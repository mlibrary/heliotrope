RESQUE_MOUNT_PATH = 'resque'.freeze

resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  current_user.present? && current_user.respond_to?(:platform_admin?) && current_user.platform_admin?
end

Rails.application.routes.draw do
  get 'dashboard', controller: :dashboard, action: :index

  mount Blacklight::Engine => '/'
  mount Riiif::Engine => '/image-service', as: 'riiif'

  constraints resque_web_constraint do
    mount ResqueWeb::Engine => "/#{RESQUE_MOUNT_PATH}"
  end

  # For anyone who doesn't meet resque_web_constraint,
  # fall through to this controller.
  get RESQUE_MOUNT_PATH, controller: :jobs, action: :forbid

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  if Rails.env.eql?('development')
    devise_for :users
  else
    # temporarily disable devise registrations and password resets for production #266
    devise_for :users, skip: [:registration, :password]
  end
  get 'users', controller: :users, action: :index, as: :users
  get 'users/:id', controller: :users, action: :show, as: :user
  get 'roles', controller: :roles, action: :index2, as: :roles
  get 'roles/:id', controller: :roles, action: :show, as: :role

  mount CurationConcerns::Engine, at: '/'
  curation_concerns_collections

  get 'concern/monographs/new', controller: 'curation_concerns/monographs', action: :new
  get 'concern/monographs/:id', controller: :monograph_catalog, action: :index, as: :monograph_catalog
  get 'concern/monographs/:id/show', controller: 'curation_concerns/monographs', action: :show, as: :monograph_show
  get 'monograph_catalog/facet/:id', controller: :monograph_catalog, action: :facet, as: :monograph_catalog_facet

  curation_concerns_basic_routes
  curation_concerns_embargo_management
  concern :exportable, Blacklight::Routes::Exportable.new

  namespace :curation_concerns, path: '/concerns' do
    resources :monographs, only: [] do
      member do
        post :publish
      end
    end
  end
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
  get '/presses' => 'presses#index'

  get '/:subdomain', controller: :press_catalog, action: :index, as: :press_catalog
  get '/:subdomain/facet', controller: :press_catalog, action: :facet

  resources :presses, path: '/', only: [:index] do
    resources :sub_brands, only: [:new, :create, :show, :edit, :update]

    resources :roles, path: 'users', only: [:index, :create, :destroy] do
      collection do
        patch :update_all
      end
    end
  end
  root 'presses#index'
end
