namespace :effective_events do

  # bundle exec rake effective_events:seed
  task seed: :environment do
    load "#{__dir__}/../../db/seeds.rb"
  end

end
