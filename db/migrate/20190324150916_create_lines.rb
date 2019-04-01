class CreateLines < ActiveRecord::Migration[5.2]
  def change
    create_table :lines do |t|
      t.string :name, null: false
      t.string :line, null: false
      t.string :letters, null: false
      t.index :line
      t.index :letters
    end
  end
end
