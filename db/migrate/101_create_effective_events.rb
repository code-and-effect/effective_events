class CreateEffectiveEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :title

      t.string :category
      t.string :slug

      t.datetime :published_start_at
      t.datetime :published_end_at
      t.boolean :legacy_draft, default: false

      t.datetime :start_at
      t.datetime :end_at

      t.datetime :registration_start_at
      t.datetime :registration_end_at
      t.datetime :early_bird_end_at

      t.integer :event_registrants_count, default: 0
      t.integer :event_addons_count, default: 0

      t.boolean :external_registration, default: false
      t.string :external_registration_url

      t.boolean :allow_blank_registrants, default: false

      t.integer :roles_mask
      t.boolean :authenticate_user, default: false

      t.boolean :delayed_payment, default: false
      t.date :delayed_payment_date

      t.timestamps
    end

    add_index :events, :title
    add_index :events, :end_at

    create_table :event_tickets do |t|
      t.integer :event_id

      t.string :title
      t.integer :capacity
      t.boolean :display_capacity, default: false

      t.boolean :waitlist, default: false

      t.string :category
      t.boolean :guest_of_member, default: false

      t.integer :non_member_price
      t.integer :member_price
      t.integer :guest_of_member_price
      t.integer :early_bird_price

      t.text :question1
      t.text :question2
      t.text :question3

      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.integer :position
      t.boolean :archived, default: false

      t.timestamps
    end

    add_index :event_tickets, :event_id, if_not_exists: true
    add_index :event_tickets, :title, if_not_exists: true

    create_table :event_registrants do |t|
      t.integer :event_id
      t.integer :event_ticket_id

      t.integer :owner_id
      t.string :owner_type

      t.integer :event_registration_id
      t.string :event_registration_type

      t.integer :user_id
      t.string :user_type

      t.integer :organization_id
      t.string :organization_type

      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :company

      t.string :number
      t.text :notes

      t.boolean :blank_registrant, default: false
      t.string :member_or_non_member_choice

      t.boolean :waitlisted, default: false
      t.boolean :promoted, default: false

      t.datetime :selected_at
      t.datetime :registered_at

      t.text :response1
      t.text :response2
      t.text :response3

      t.integer :purchased_order_id
      t.integer :price

      t.boolean :archived, default: false
      t.boolean :created_by_admin, default: false

      t.timestamps
    end

    add_index :event_registrants, :event_registration_id, if_not_exists: true
    add_index :event_registrants, :event_ticket_id, if_not_exists: true
    add_index :event_registrants, :archived, if_not_exists: true
    add_index :event_registrants, :registered_at, if_not_exists: true

    create_table :event_products do |t|
      t.integer :event_id

      t.string :title
      t.integer :capacity

      t.integer :price

      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.integer :position
      t.boolean :archived, default: false

      t.timestamps
    end

    add_index :event_products, :event_id, if_not_exists: true
    add_index :event_products, :position, if_not_exists: true

    create_table :event_addons do |t|
      t.integer :event_id
      t.integer :event_product_id

      t.integer :owner_id
      t.string :owner_type

      t.integer :event_registration_id
      t.string :event_registration_type

      t.string :first_name
      t.string :last_name
      t.string :email

      t.text :notes

      t.integer :purchased_order_id
      t.integer :price

      t.boolean :archived, default: false
      t.boolean :created_by_admin, default: false

      t.timestamps
    end

    add_index :event_addons, :event_registration_id, if_not_exists: true
    add_index :event_addons, :event_product_id, if_not_exists: true

    create_table :event_registrations do |t|
      t.string :token

      t.integer :event_id

      t.integer :owner_id
      t.string :owner_type

      t.integer :user_id
      t.string :user_type

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at
      t.datetime :completed_at

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :event_registrations, [:owner_id, :owner_type]
    add_index :event_registrations, :status
    add_index :event_registrations, :token

    create_table :event_ticket_selections do |t|
      t.integer :event_registration_id
      t.string :event_registration_type

      t.string :event_ticket_id
      t.integer :quantity

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :event_ticket_selections, :event_registration_id, if_not_exists: true

    create_table :event_notifications do |t|
      t.references :event

      t.string :category
      t.integer :reminder

      t.string :from
      t.string :subject
      t.text :body

      t.string :cc
      t.string :bcc
      t.string :content_type

      t.datetime :started_at
      t.datetime :completed_at

      t.datetime :updated_at
      t.datetime :created_at
    end

  end
end
