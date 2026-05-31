# frozen_string_literal: true
ActiveEncode::Engine.routes.draw do
  resources :encode_record, only: [:show]
end
