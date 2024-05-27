# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveEvents::Engine => '/', as: 'effective_events'
end

EffectiveEvents::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do

    # Event Category routes
    match 'events/:category', to: 'events#index', via: :get, constraints: lambda { |req|
      EffectiveEvents.categories.map(&:parameterize).include?(req.params['category'])
    }

    match "events/:category/:id", to: 'events#show', via: :get, constraints: lambda { |req|
      EffectiveEvents.categories.map(&:parameterize).include?(req.params['category'])
    }

    resources :events, only: [:index, :show] do
      resources :event_registrations, only: [:new, :show, :destroy] do
        resources :build, controller: :event_registrations, only: [:show, :update]

        put :update_blank_registrants, on: :member
      end
    end
  end

  namespace :admin do
    resources :events, except: [:show]
    resources :event_registrations, only: [:index, :show]
    resources :event_notifications, except: [:show]

    resources :event_tickets, except: [:show] do
      post :archive, on: :member
      post :unarchive, on: :member
    end

    resources :event_products, except: [:show] do
      post :archive, on: :member
      post :unarchive, on: :member
    end

    resources :event_registrants, except: [:show] do
      post :archive, on: :member
      post :unarchive, on: :member
    end

    resources :event_addons, except: [:show] do
      post :archive, on: :member
      post :unarchive, on: :member
    end

  end

end
