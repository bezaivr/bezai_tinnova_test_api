Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post 'auth/login', to: 'authentication#login'

  resources :beers, only: :index
  get 'beers/:api_id', to: 'beers#show', via: [:options]
  match 'beers/favorite/:api_id', to: 'beers#choose_favorite', via: %i[put patch]
end
