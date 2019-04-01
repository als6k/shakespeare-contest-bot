# https://scoutapp.com/blog/how-to-make-text-searches-in-postgresql-faster-with-trigram-similarity

class AddTrigramIndexesToLines < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE INDEX lines_on_line_idx ON lines USING gin(line gin_trgm_ops);
      CREATE INDEX lines_on_letters_idx ON lines USING gin(letters gin_trgm_ops);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX lines_on_letters_idx;
      DROP INDEX lines_on_line_idx;
    SQL
  end
end
