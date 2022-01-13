# Effective Events

Events, event registrants, event tickets and event products.

## Getting Started

This requires Rails 6+ and Twitter Bootstrap 4 and just works with Devise.

Please first install the [effective_datatables](https://github.com/code-and-effect/effective_datatables) gem.

Please download and install the [Twitter Bootstrap4](http://getbootstrap.com)

Add to your Gemfile:

```ruby
gem 'haml-rails' # or try using gem 'hamlit-rails'
gem 'effective_events'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_events:install
```

The generator will install an initializer which describes all configuration options and creates a database migration.

If you want to tweak the table names, manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

Use the following datatables to display to your user the events:

```haml
%h2 Events
- datatable = EffectiveEventsDatatable.new
```

and

```
Add a link to the admin menu:

```haml
- if can? :admin, :effective_events
  - if can? :index, Effective::Event
    = nav_link_to 'Events', effective_events.admin_events_path
```

## Configuration

## Authorization

All authorization checks are handled via the effective_resources gem found in the `config/initializers/effective_resources.rb` file.

## Permissions

The permissions you actually want to define are as follows (using CanCan):

```ruby
can([:index, :show], Effective::Event) { |event| !event.draft? }
can([:new, :create], EffectiveEvents.EventRegistration)
can([:show, :index], Effective::EventRegistrant) { |registrant| registrant.owner == user || registrant.owner.blank? }
can([:show, :index], Effective::EventPurchase) { |purchase| purchase.owner == user || purchase.owner.blank? }
can([:show, :index], EffectiveEvents.EventRegistration) { |registration| registration.owner == user }
can([:update, :destroy], EffectiveEvents.EventRegistration) { |registration| registration.owner == user && !registration.was_submitted? }

if user.admin?
  can :admin, :effective_events

  can(crud - [:destroy], Effective::Event)
  can(:destroy, Effective::Event) { |et| et.event_registrants_count == 0 }

  can(crud - [:destroy], Effective::EventRegistrant)
  can(:mark_paid, Effective::EventRegistrant) { |er| !er.event_registration_id.present? }
  can(:destroy, Effective::EventRegistrant) { |er| !er.purchased? }

  can(crud - [:destroy], Effective::EventPurchase)
  can(:mark_paid, Effective::EventPurchase) { |er| !er.event_registration_id.present? }
  can(:destroy, Effective::EventPurchase) { |er| !er.purchased? }

  can(crud - [:destroy], Effective::EventTicket)
  can(:destroy, Effective::EventTicket) { |et| et.purchased_event_registrants_count == 0 }

  can(crud - [:destroy], Effective::EventProduct)
  can(:destroy, Effective::EventProduct) { |et| et.purchased_event_purchases_count == 0 }

  can([:index, :show], EffectiveEvents.EventRegistration)
end
```

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Testing

Run tests by:

```ruby
rails test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
