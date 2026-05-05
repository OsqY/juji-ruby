class CreateWhiteboards < ActiveRecord::Migration[8.1]
  def change
    create_table :whiteboards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :token
      t.integer :width, default: 1200
      t.integer :height, default: 800
      t.string :background_color, default: '#FFFFFF'

      t.timestamps
    end
    add_index :whiteboards, :token, unique: true
  end
end
