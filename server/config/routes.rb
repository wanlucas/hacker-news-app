Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  
  namespace :api do
    get 'stories/update', to: 'stories#update'

    resources :stories, only: [:index] do
      collection do
        get :search
      end
    end
  end
end
