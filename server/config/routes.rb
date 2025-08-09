Rails.application.routes.draw do
  namespace :api do
    resources :stories, only: [:index] do
    end
  end
end
