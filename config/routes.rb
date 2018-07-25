# frozen_string_literal: true

resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  current_user.present? && current_user.respond_to?(:platform_admin?) && current_user.platform_admin?
end

platform_administrator_constraint = lambda do |request|
  current_user = request.env['warden'].user
  current_user.present? && current_user.respond_to?(:platform_admin?) && current_user.platform_admin?
end

Rails.application.routes.draw do
  namespace :api, constraints: ->(req) { req.format == :json } do
    resource :token, only: %i[show]
    scope module: :v1, constraints: API::Version.new('v1', true) do
      get 'lessee', controller: :lessees, action: :find, as: :find_lessee
      resources :lessees, only: %i[index show create destroy] do
        resources :products, only: %i[index show create update destroy]
      end
      get 'product', controller: :products, action: :find, as: :find_product
      resources :products, only: %i[index show create destroy] do
        resources :lessees, only: %i[index show create update destroy]
      end
    end
  end

  constraints platform_administrator_constraint do
    resources :api_requests, only: %i[index show destroy]

    resources :users, only: [] do
      member do
        put :tokenize
      end
    end
    resources :groupings do
      resources :lessees, only: %i[create destroy]
    end
    resources :institutions
    resources :lessees do
      resources :groupings, only: %i[create destroy]
      resources :products, only: %i[create destroy]
    end
    resources :components do
      resources :products, only: %i[create destroy]
    end
    resources :products do
      resources :components, only: %i[create destroy]
      resources :lessees, only: %i[create destroy]
    end
  end

  resources :institutions, only: [] do
    member do
      get :login
      get :help
    end
  end

  resources :products, only: [] do
    member do
      get :purchase
      get :help
    end
  end

  get 'epubs/:id', controller: :e_pubs, action: :show, as: :epub
  get 'epubs/:id/*file', controller: :e_pubs, action: :file, as: :epub_file
  get 'epub_search/:id', controller: :e_pubs, action: :search, as: :epub_search
  get 'epubs_download_chapter/:id', controller: :e_pubs, action: :download_chapter, as: :epub_download_chapter
  get 'embed', controller: :embed, action: :show
  get 'fulcrum', controller: :fulcrum, action: :index, as: :fulcrum
  get 'fulcrum/:partial', controller: :fulcrum, action: :show, as: :partial_fulcrum
  get 'analytics', controller: :analytics, action: :show
  get 'webgl/:id', controller: :webgls, action: :show, as: :webgl
  get 'webgl/:id/*file', controller: :webgls, action: :file, as: :webgl_file
  post 'featured_representatives', controller: :featured_representatives, action: :save
  delete 'featured_representatives', controller: :featured_representatives, action: :delete

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

  devise_for :users, path: '', controllers: { sessions: 'sessions' }
  get 'login', controller: :sessions, action: :new, as: :new_user_session
  get 'logout', controller: :sessions, action: :destroy, as: :destroy_user_session
  get 'default_login', to: 'sessions#default_login', as: :default_login
  get 'shib_login(/*resource)', to: 'sessions#shib_login', as: :shib_login
  get 'shib_session(/*resource)', to: 'sessions#shib_session', as: :shib_session
  resource :authentications, only: %i[new create destroy]

  unless /^production$/i.match?(Rails.env)
    get 'Shibboleth.sso/DiscoFeed', controller: :shibboleths, action: :discofeed
    get 'Shibboleth.sso/Help', controller: :shibboleths, action: :help
    get 'Shibboleth.sso/Login', controller: :shibboleths, action: :new
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
  patch 'concern/monographs/:id/reindex', controller: 'hyrax/monographs', action: :reindex, as: :monograph_reindex
  get 'monograph_catalog/facet/:id', controller: :monograph_catalog, action: :facet, as: :monograph_catalog_facet

  curation_concerns_basic_routes
  concern :exportable, Blacklight::Routes::Exportable.new

  namespace :hyrax, path: '/concerns' do
    resources :monographs, only: [] do
      member do
        post :publish
      end
    end
  end

  constraints platform_administrator_constraint do
    resource :manifests, path: 'concern/monographs/:id/manifest', only: %i[new edit update create destroy], as: :monograph_manifests

    resource :monograph_manifests, path: 'concern/monographs/:id/manifest', only: [:show] do
      member do
        get :export
        patch :import
        get :preview
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

  get '/presses' => 'presses#index'
  resources :presses, only: %i[new create edit update]
  resources :presses, path: '/', only: %i[index edit] do
    resources :roles, path: 'users', only: %i[index create destroy] do
      collection do
        patch :update_all
      end
    end
  end

  get '/robots.txt' => 'robots#robots'

  get '/favicon.ico', to: redirect('/favicon/favicon.ico')
  # TODO: Used in dev only? If apache is in front I don't think this ever happens?
  # Might fix #379 but need to check
  get '/favicon/favicon.ico', to: redirect('/favicon.ico')

  get ':subdomain', controller: :press_catalog, action: :index, as: :press_catalog
  get ':subdomain/facet', controller: :press_catalog, action: :facet

  root 'presses#index'
end
