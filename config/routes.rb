# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveEvents::Engine => '/', as: 'effective_events'
end

EffectiveEvents::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :events, only: [:index, :show]
  end

  namespace :admin do
    resources :events, except: [:show]
    resources :event_tickets, except: [:show]
    resources :event_registrants, except: [:show]
  end

end
