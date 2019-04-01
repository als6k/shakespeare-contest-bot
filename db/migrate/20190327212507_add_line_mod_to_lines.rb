class AddLineModToLines < ActiveRecord::Migration[5.2]
  def change
    add_column :lines, :line_mod, :string
    add_index :lines, :line_mod
  end
end
