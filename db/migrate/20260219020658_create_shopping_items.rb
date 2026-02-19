class CreateShoppingItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_items do |t|
      t.string :name
      t.string :quantity
      t.boolean :bought, default: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
