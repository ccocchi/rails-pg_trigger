require "test_helper"

class TestTriggerClass < Minitest::Test
  attr_reader :trigger

  def setup
    @trigger = PgTrigger::Trigger.new
  end

  def test_on
    trigger.on("users")
    assert_equal "users", trigger.table
  end

  def test_after
    trigger.after(:insert, :update)

    assert_equal :after, trigger.timing
    assert_equal [:insert, :update], trigger.events
  end

  def test_before
    trigger.before(:delete)

    assert_equal :before, trigger.timing
    assert_equal [:delete], trigger.events
  end

  def test_after_events_aliases
    trigger.after(:create, :destroy)
    assert_equal [:insert, :delete], trigger.events
  end

  def test_before_events_aliases
    trigger.before(:create, :destroy)
    assert_equal [:insert, :delete], trigger.events
  end

  def test_of
    trigger.of(:id, :created_at)
    assert_equal [:id, :created_at], trigger.columns
  end

  def test_named
    trigger.named("users_after_insert_tr")
    assert_equal "users_after_insert_tr", trigger.name
  end

  def test_content_with_trailing_spaces
    trigger.named("ok_tr") { "SELECT 1;\n" }
    assert_equal "SELECT 1;", trigger.content
  end

  def test_ensure_colon_after_content
    trigger.named("ok_tr") { "SELECT 1" }
    assert_equal "SELECT 1;", trigger.content
  end

  def test_inferred_name
    trigger.on("users").before(:insert, :update)
    assert_equal "users_before_insert_or_update_tr", trigger.name
  end

  def test_chaining
    trigger.after(:update).of(:a, :b) { "SQL" }

    assert_equal :after, trigger.timing
    assert_equal [:update], trigger.events
    assert_equal [:a, :b], trigger.columns
    assert_equal "SQL;", trigger.content
  end

  def test_same_content_with_single_line_strings
    trigger.named("first") { "UPDATE flurbos SET cnt = 100" }
    other = PgTrigger::Trigger.new.named("first") { "UPDATE flurbos SET cnt = 100" }

    assert trigger.same_content_as?(other)
  end

  def test_same_content_with_multiline_strings
    trigger.named("first") do
      <<-SQL
        UPDATE flurbos SET cnt = 100
          WHERE id = 1
      SQL
    end
    other = PgTrigger::Trigger.new.named("first") do
      <<~SQL
        UPDATE flurbos
        SET cnt = 100 WHERE id = 1
      SQL
    end

    assert trigger.same_content_as?(other)
  end

  def test_create_function_sql
    content = "UPDATE posts SET comments_count = comments_count + 1"
    trigger.on("comments").after(:insert).named("foo_tr") { content }

    sql = trigger.create_function_sql

    assert_match %r{CREATE OR REPLACE FUNCTION foo_tr\(\) RETURNS TRIGGER}, sql
    assert_match %r{BEGIN\s+#{Regexp.escape(content)};\s+RETURN NULL;\s+END}, sql
  end

  def test_create_function_sql_with_multiline_content
    content = <<-SQL
      UPDATE posts SET comments_count = comments_count + 1
      WHERE posts.id IN (
        SELECT NEW.post_id
      )
    SQL
    trigger.on("comments").after(:insert).named("foo_tr") { content }

    expected = <<~SQL
      CREATE OR REPLACE FUNCTION foo_tr() RETURNS TRIGGER
      AS $$
        BEGIN
          UPDATE posts SET comments_count = comments_count + 1
          WHERE posts.id IN (
            SELECT NEW.post_id
          );
          RETURN NULL;
        END
      $$ LANGUAGE plpgsql;
    SQL

    assert_equal expected, trigger.create_function_sql
  end

  def test_drop_function_sql
    trigger.named("foo_tr")
    assert_equal "DROP FUNCTION IF EXISTS foo_tr;", trigger.drop_function_sql
  end

  def test_create_trigger_sql
    trigger.on("comments").after(:insert, :update).named("foo_tr")
    expected = <<~SQL
      CREATE TRIGGER foo_tr
      AFTER INSERT OR UPDATE ON "comments"
      FOR EACH ROW
      EXECUTE FUNCTION foo_tr();
    SQL

    assert_equal expected, trigger.create_trigger_sql
  end

  def test_create_trigger_sql_with_condition
    trigger.on("comments").after(:insert).where("NEW.published").named("foo_published_tr")
    expected = <<~SQL
      CREATE TRIGGER foo_published_tr
      AFTER INSERT ON "comments"
      FOR EACH ROW
      WHEN (NEW.published)
      EXECUTE FUNCTION foo_published_tr();
    SQL

    assert_equal expected, trigger.create_trigger_sql
  end

  def test_from_definition_from_simple_trigger
    defn = <<~SQL
      CREATE TRIGGER comments_after_update_tr AFTER UPDATE OF content, title ON public.comments FOR EACH ROW EXECUTE FUNCTION comments_after_update_tr();
    SQL

    tr = PgTrigger::Trigger.from_definition(defn)

    assert_equal "comments_after_update_tr", tr.name
    assert_equal :after, tr.timing
    assert_equal [:update], tr.events
    assert_equal "comments", tr.table
    assert_equal ["content", "title"], tr.columns
  end

  def test_from_definition_with_full_trigger
    defn = <<~SQL
      CREATE TRIGGER comments_after_insert_tr BEFORE INSERT OR UPDATE ON public.comments FOR EACH ROW WHEN (NEW.is_published) EXECUTE FUNCTION comments_after_insert_tr();
    SQL

    tr = PgTrigger::Trigger.from_definition(defn)

    assert_equal "comments_after_insert_tr", tr.name
    assert_equal :before, tr.timing
    assert_equal [:insert, :update], tr.events
    assert_equal "comments", tr.table
    assert_equal "NEW.is_published", tr.where_clause
  end

  def test_invalid_definition
    tr = PgTrigger::Trigger.from_definition("invalid")
    assert_nil tr
  end

  def test_invalid_definition_raise_option
    PgTrigger.raise_on_invalid_definition = true

    assert_raises PgTrigger::InvalidTriggerDefinition do
      PgTrigger::Trigger.from_definition("invalid")
    end
  ensure
    PgTrigger.raise_on_invalid_definition = false
  end
end
