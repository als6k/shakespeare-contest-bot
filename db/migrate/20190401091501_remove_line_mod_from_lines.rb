class RemoveLineModFromLines < ActiveRecord::Migration[5.2]
  def up
    remove_column :lines, :line_mod
  end

  def down
    add_column :lines, :line_mod, :string
    add_index :lines, :line_mod
  end
end
