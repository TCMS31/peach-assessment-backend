# frozen_string_literal: true

Rails.application.routes.draw do
  # Probe for the container healthcheck; verifies the database, not just Puma.
  get '/health', to: 'health#show'

  resources :categories, only: %i[index]
  resources :merchants, only: %i[index]
  resources :transactions, only: %i[index show update]
end
