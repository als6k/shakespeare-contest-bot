class CreateLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :logs do |t|
      t.integer :task_id, null: false
      t.datetime :created_at, null: false
      t.integer :level, null: false
      t.string :question, limit: 255, null: false
      t.string :answer, limit: 255
      t.string :server_response, limit: 255
      t.float :search_time
    end
  end
end
