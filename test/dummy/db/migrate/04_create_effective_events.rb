class CreateEffectiveEvents < ActiveRecord::Migration[6.0]
  def change
    # Events
    create_table :events do |t|
      t.string    :title

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :events, :title
  end
end
