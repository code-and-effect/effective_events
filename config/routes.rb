# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveEvents::Engine => '/', as: 'effective_events'
end

EffectiveEvents::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :events, only: [:index, :show] do
      resources :event_registrations, only: [:new, :show, :destroy] do
        resources :build, controller: :event_registrations, only: [:show, :update]
      end
    end
  end

  namespace :admin do
    resources :events, except: [:show]
    resources :event_tickets, except: [:show]
    resources :event_products, except: [:show]
    resources :event_registrants, except: [:show]
    resources :event_addons, except: [:show]
    resources :event_registrations, only: [:index, :show]
  end

end
