class CreateTgBots < ActiveRecord::Migration[7.0]
  def change
    create_table :tg_bots do |t|
      t.string :chat_id
      t.integer :address_id
      t.string :address_hash
      t.boolean :is_use, default: true
      t.decimal :change_balance, precision: 30, scale: 0

      t.timestamps
    end
    add_index :tg_bots, :chat_id
    add_index :tg_bots, :address_id
    add_index :tg_bots, :address_hash
    add_index :tg_bots, [:chat_id, :address_hash], unique: true
  end
end
