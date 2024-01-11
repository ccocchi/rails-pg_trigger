class Comment < ActiveRecord::Base
  belongs_to :post

  trigger.after(:insert) do
    <<-SQL
      UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.comment_id;
    SQL
  end

  trigger.after(:delete) do
    <<-SQL
      UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.comment_id;
    SQL
  end
end
