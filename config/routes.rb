Rails.application.routes.draw do
  get '/', to: proc { [200, {}, ['']] }
  
  resources :jobs, only: [:index, :create]

  # keep last
  match '*path', via: [:all], to: 'application#not_found'
end
