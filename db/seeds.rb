puts "Running effective_events seeds"

now = Time.zone.now

if Rails.env.test?
  Effective::Event.destroy_all
  ActionText::RichText.where(record_type: ['Effective::Event', 'Effective::Ticket']).delete_all
end

# Build an example event
event = Effective::Event.create!(
  title: "#{now.year} Main Event",
  rich_text_excerpt: '<p>This is a great event</p>',
  rich_text_body: '<p>This is a really great event!</p>',

  published_start_at: Time.zone.now,
  start_at: (now + 1.week),
  end_at: (now + 1.week + 1.hour),

  registration_start_at: now,
  registration_end_at: (now + 6.days),
  early_bird_end_at: (now + 3.days)
)

event.event_tickets.create!(
  title: 'Ticket A 10 Seats',
  capacity: 10,
  non_member_price: 100_00,
  early_bird_price: 50_00,
  member_price: 75_00,
  qb_item_name: 'Tickets'
)

event.event_tickets.create!(
  title: 'Ticket B 20 Seats',
  capacity: 20,
  non_member_price: 200_00,
  early_bird_price: 150_00,
  member_price: 75_00,
  qb_item_name: 'Tickets'
)

event.event_tickets.create!(
  title: 'Ticket C Unlimited Seats',
  capacity: nil,
  non_member_price: 200_00,
  early_bird_price: 150_00,
  member_price: 75_00,
  qb_item_name: 'Tickets'
)

event.event_products.create!(
  title: 'T-Shirt',
  price: 100_00,
  qb_item_name: 'Addons'
)
