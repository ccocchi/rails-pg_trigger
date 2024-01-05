# frozen_string_literal: true

require "test_helper"

class TestTriggerProxy < Minitest::Test
  def setup
    @proxy = PgTrigger::Model::Proxy.new
  end

  def test_chaining
    @proxy.after(:update).of(:a, :b) { "SQL" }

    assert_equal :after, @proxy.timing
    assert_equal [:update], @proxy.events
    assert_equal [:a, :b], @proxy.columns
    assert_equal "SQL", @proxy.content
  end
end
