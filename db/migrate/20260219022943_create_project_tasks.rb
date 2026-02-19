class CreateProjectTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :project_tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name
      t.boolean :completed, default: false

      t.timestamps
    end
  end
end
