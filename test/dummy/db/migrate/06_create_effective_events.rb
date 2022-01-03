class CreateEffectiveEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :title

      t.string :slug
      t.boolean :draft, default: false

      t.datetime :start_at
      t.datetime :end_at

      t.datetime :registration_start_at
      t.datetime :registration_end_at
      t.datetime :early_bird_end_at

      t.integer :event_registrants_count, default: 0

      t.integer :roles_mask
      t.boolean :authenticate_user, default: false

      t.timestamps
    end

    add_index :events, :title
    add_index :events, :end_at

    create_table :event_tickets do |t|
      t.integer :event_id

      t.string :title
      t.integer :capacity

      t.integer :regular_price
      t.integer :early_bird_price

      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.integer :position

      t.timestamps
    end

    create_table :event_registrants do |t|
      t.integer :event_id
      t.integer :event_ticket_id

      t.integer :owner_id
      t.string :owner_type

      t.integer :event_registration_id
      t.string :event_registration_type

      t.string :first_name
      t.string :last_name
      t.string :email

      t.string :company
      t.string :number
      t.text :notes

      t.integer :purchased_order_id
      t.integer :price

      t.timestamps
    end
  end
end
