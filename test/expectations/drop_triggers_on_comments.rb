# This migration was auto-generated via `rake db:triggers:migration'.

class DropTriggersOnComments < ActiveRecord::Migration[7.0]
  def up
    drop_trigger "comments_before_update_of_title_tr", <<~SQL
      DROP TRIGGER IF EXISTS comments_before_update_of_title_tr ON "comments";
      DROP FUNCTION IF EXISTS comments_before_update_of_title_tr;
    SQL
  end

  def down
    create_trigger "comments_before_update_of_title_tr", <<~SQL
      CREATE OR REPLACE FUNCTION comments_before_update_of_title_tr() RETURNS TRIGGER
      AS $$
        BEGIN
          UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
          RETURN NULL;
        END
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER comments_before_update_of_title_tr
      BEFORE UPDATE OF title ON "comments"
      FOR EACH ROW
      EXECUTE FUNCTION comments_before_update_of_title_tr();
    SQL
  end
end
