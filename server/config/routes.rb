Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  get '/health', to: proc { [200, {}, ['OK']] }
  get '/up', to: proc { [200, {}, ['OK']] }
  
  namespace :api do
    get 'stories/update', to: 'stories#update'

    resources :stories, only: [:index] do
      collection do
        get :search
      end
    end
  end
end
