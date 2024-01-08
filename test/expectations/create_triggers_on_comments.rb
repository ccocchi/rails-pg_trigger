# This migration was auto-generated via `rake db:triggers:migration'.

class CreateTriggersOnComments < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION comments_after_insert_tr() RETURNS TRIGGER
      AS $$
        BEGIN
          UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
          RETURN NULL;
        END
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER comments_after_insert_tr
      AFTER INSERT ON "comments"
      FOR EACH ROW
      EXECUTE FUNCTION comments_after_insert_tr();

    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS comments_after_insert_tr;
      DROP TRIGGER IF EXISTS comments_after_insert_tr ON "comments";
    SQL
  end
end
