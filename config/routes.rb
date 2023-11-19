Rails.application.routes.draw do
  get 'nfts/create', to: 'nfts#create'
  resources :nfts, only: %i[index show new]
  get 'greetings/index'

  get "medals/exchanged", to: "medals#exchanged"
  get 'medals/list', to:'medals#list'
  resources :medals
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
