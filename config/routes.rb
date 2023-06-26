Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :categories, only: %i[index]
  resources :merchants, only: %i[index]
  resources :transactions, only: %i[index show update]
end
