Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # The web app manifest gives the page an install icon and a theme color.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resources :campaigns, only: :show do
    resources :donations, only: [ :index, :create ]
  end

  root "campaigns#show"
end
