# This migration was auto-generated via `rake db:triggers:migration'.

class UpdateTriggersOnComments < ActiveRecord::Migration[7.0]
  def up
    create_trigger "comments_before_update_tr", <<~SQL
      CREATE OR REPLACE FUNCTION comments_before_update_tr() RETURNS TRIGGER
      AS $$
        BEGIN
          UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
          RETURN NULL;
        END
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER comments_before_update_tr
      BEFORE UPDATE ON "comments"
      FOR EACH ROW
      EXECUTE FUNCTION comments_before_update_tr();

    SQL

    drop_trigger "comments_before_update_tr", <<~SQL
      DROP TRIGGER IF EXISTS comments_before_update_tr ON "comments";
      DROP FUNCTION IF EXISTS comments_before_update_tr;
    SQL
  end

  def down
    drop_trigger "comments_before_update_tr", <<~SQL
      DROP TRIGGER IF EXISTS comments_before_update_tr ON "comments";
      DROP FUNCTION IF EXISTS comments_before_update_tr;
    SQL

    create_trigger "comments_before_update_tr", <<~SQL
      CREATE OR REPLACE FUNCTION comments_before_update_tr() RETURNS TRIGGER
      AS $$
        BEGIN
          UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
          RETURN NULL;
        END
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER comments_before_update_tr
      BEFORE UPDATE ON "comments"
      FOR EACH ROW
      EXECUTE FUNCTION comments_before_update_tr();

    SQL
  end
end
