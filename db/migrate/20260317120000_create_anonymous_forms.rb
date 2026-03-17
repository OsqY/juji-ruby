class CreateAnonymousForms < ActiveRecord::Migration[8.1]
  def change
    create_table :anonymous_forms do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :response_limit, null: false, default: 1
      t.integer :responses_count, null: false, default: 0
      t.string :token, null: false

      t.timestamps
    end

    add_index :anonymous_forms, :token, unique: true

    create_table :anonymous_form_questions do |t|
      t.references :anonymous_form, null: false, foreign_key: true
      t.string :prompt, null: false
      t.integer :question_type, null: false, default: 2
      t.boolean :required, null: false, default: true
      t.text :options_text
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    create_table :anonymous_form_responses do |t|
      t.references :anonymous_form, null: false, foreign_key: true
      t.json :answers, null: false, default: {}

      t.timestamps
    end
  end
end
