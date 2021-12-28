# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveEvents::Engine => '/', as: 'effective_events'
end

EffectiveEvents::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :events, except: [:show, :destroy]
  end

  namespace :admin do
    resources :events, except: [:show]
  end

end
