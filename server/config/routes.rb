Rails.application.routes.draw do
  namespace :api do
    resources :stories, only: [:index] do
      collection do
        get :search
      end
    end
  end
end
