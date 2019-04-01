class AddTsvectorColumnToLines < ActiveRecord::Migration[5.2]
  def up
    add_column :lines, :tsv, :tsvector
    add_index :lines, :tsv, using: 'gin'
    add_column :lines, :created_at, :datetime

    execute <<-SQL
      CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
      ON lines FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(
        tsv, 'pg_catalog.simple', line
      );
    SQL

    now = Time.current.to_s(:db)
    update("UPDATE lines SET created_at = '#{now}'")
  end

  def down
    execute <<-SQL
      DROP TRIGGER tsvectorupdate ON lines
    SQL

    remove_column :lines, :tsv, :created_at
  end
end
