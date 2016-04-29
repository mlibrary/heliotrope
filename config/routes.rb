Rails.application.routes.draw do
  mount Blacklight::Engine => '/'
  resque_web_constraint = lambda do |request|
    current_user = request.env['warden'].user
    current_user.present? && current_user.respond_to?(:platform_admin?) && current_user.platform_admin?
  end

  constraints resque_web_constraint do
    mount ResqueWeb::Engine => '/resque'
  end

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users
  mount CurationConcerns::Engine, at: '/'
  curation_concerns_collections
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

  get '/:subdomain', controller: :press_catalog, action: :index, as: :press_catalog

  resources :presses, path: '/', only: [:index] do
    resources :roles, path: 'users', only: [:index, :create, :destroy] do
      collection do
        patch :update_all
      end
    end
  end

  root 'presses#index'
end
