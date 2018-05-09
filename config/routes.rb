Rails.application.routes.draw do
  get '/', to: proc { [200, {}, ['']] }
  
  resources :jobs, only: [:index, :create]
end
