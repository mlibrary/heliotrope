# frozen_string_literal: true

resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  current_user.present? && current_user.respond_to?(:platform_admin?) && current_user.platform_admin?
end

platform_administrator_constraint = lambda do |request|
  current_user = request.env['warden'].user
  current_user.present? && current_user.respond_to?(:platform_admin?) && current_user.platform_admin?
end

COUNTER_REPORT_ID_CONSTRAINT = { id: /dr|dr_d1|dr_d2|ir|ir_a1|ir_m1|pr|pr_p1|tr|tr_b1|tr_b2|tr_b3|tr_j1|tr_j2|tr_j3|tr_j4/i }.freeze

Rails.application.routes.draw do
  namespace :api, constraints: ->(req) { req.format == :json } do
    resource :token, only: %i[show]

    namespace :sushi do
      scope module: :v5, constraints: API::Sushi::Version.new('v5', true) do
        get '', controller: :service, action: :sushi
        get 'status', controller: :service, action: :status
        get 'members', controller: :service, action: :members
        get 'reports', controller: :service, action: :reports
        resources :reports, only: %i[show], constraints: COUNTER_REPORT_ID_CONSTRAINT
      end
    end

    scope module: :v1, constraints: API::Version.new('v1', true) do
      get 'lessee', controller: :lessees, action: :find, as: :find_lessee
      resources :lessees, only: %i[index show create destroy] do
        resources :products, only: %i[index show create update destroy]
      end
      get 'component', controller: :components, action: :find, as: :find_component
      resources :components, only: %i[index show create destroy] do
        resources :products, only: %i[index show create update destroy]
      end
      get 'product', controller: :products, action: :find, as: :find_product
      resources :products, only: %i[index show create destroy] do
        resources :components, only: %i[index show create update destroy]
        resources :lessees, only: %i[index show create update destroy]
      end
      get 'individual', controller: :individuals, action: :find, as: :find_individual
      resources :individuals, only: %i[index show create update destroy]
      get 'institution', controller: :institutions, action: :find, as: :find_institution
      resources :institutions, only: %i[index show create update destroy]
    end
  end

  constraints platform_administrator_constraint do
    get 'fulcrum', controller: :fulcrum, action: :dashboard, as: :fulcrum
    get 'fulcrum/:partials', controller: :fulcrum, action: :index, as: :fulcrum_partials
    get 'fulcrum/:partials/:id', controller: :fulcrum, action: :show, as: :fulcrum_partial
    resources :api_requests, only: %i[index show destroy]
    resources :individuals
    resources :institutions
    resources :lessees do
      resources :products, only: %i[create destroy]
    end
    resources :components do
      resources :products, only: %i[create destroy]
    end
    resources :products do
      resources :components, only: %i[create destroy]
      resources :lessees, only: %i[create destroy]
      resources :policies, only: %i[new]
    end
    resources :policies, except: %i[edit update]
    resources :customers, only: %i[index] do
      resources :counter_reports, only: %i[index show edit update], constraints: COUNTER_REPORT_ID_CONSTRAINT
    end
    resource :manifests, path: 'concern/monographs/:id/manifest', only: %i[new edit update create destroy], as: :monograph_manifests
    resource :monograph_manifests, path: 'concern/monographs/:id/manifest', only: [:show] do
      member do
        get :export
        patch :import
        get :preview
      end
    end
    get 'blank_csv_template', controller: :metadata_template, action: :export, as: :blank_csv_template
    resources :users, only: %i[new edit create update delete] do
      member do
        put :tokenize
      end
    end
    scope module: :hyrax do
      resources :users, only: %i[index show]
    end
  end

  resources :counter_reports, only: %i[index show edit update], constraints: COUNTER_REPORT_ID_CONSTRAINT

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

  get 'epubs_access/:id', controller: :e_pubs, action: :access, as: :epub_access
  get 'epubs/:id', controller: :e_pubs, action: :show, as: :epub
  get 'epubs/:id/*file', controller: :e_pubs, action: :file, as: :epub_file
  get 'epub_search/:id', controller: :e_pubs, action: :search, as: :epub_search
  get 'epubs_download_chapter/:id', controller: :e_pubs, action: :download_chapter, as: :epub_download_chapter
  get 'epubs_download_interval/:id', controller: :e_pubs, action: :download_interval, as: :epub_download_interval
  get 'embed', controller: :embed, action: :show
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
  resource :authentications, only: %i[show new create destroy]
  get 'discovery_feed', controller: :sessions, action: :discovery_feed
  get 'discovery_feed/:id', controller: :sessions, action: :discovery_feed
  unless Rails.env.production?
    get 'Shibboleth.sso/Help', controller: :shibboleths, action: :help
    get 'Shibboleth.sso/Login', controller: :shibboleths, action: :new
  end

  get '/', to: redirect('/index.html')

  # Hyrax routes we wish to hide need to be defined before mounting the Hyrax::Engine
  # and they need to go somewhere so redirect them to root a.k.a. '/'
  scope module: :hyrax do
    resources :users, only: %i[index show], to: redirect('/')
  end

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
