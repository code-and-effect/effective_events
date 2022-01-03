class CreateEffectiveEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :title
      t.text :body
      t.datetime :start_at
      t.datetime :end_at
      t.datetime :registration_start_at
      t.datetime :registration_end_at
      t.datetime :early_bird_end_at

      t.timestamps
    end

    add_index :events, :title

    create_table :event_tickets do |t|
      t.integer :event_id
      t.string :title
      t.integer :capacity
      t.integer :regular_price
      t.integer :early_bird_price
      t.boolean :tax_exempt, default: false
      t.integer :roles_mask
      t.integer :event_registrants_count

      t.timestamps
    end

    create_table :event_registrants do |t|
      t.string :user_type
      t.integer :user_id

      t.integer :event_id
      t.integer :event_ticket_id

      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :company
      t.string :number

      t.text :restrictions

      t.timestamps
    end
  end
end
