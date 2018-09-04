Rails.application.routes.draw do
  root to: 'uploads#new'

  resources :jobs, only: [:index, :create]

  mount Cfa::Styleguide::Engine => '/cfa'

  # keep last
  match '*path', via: [:all], to: 'application#not_found'
end
