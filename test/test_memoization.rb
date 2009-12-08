#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'forwardable'
require 'gluon'
require 'test/unit'

module Gluon::Test
  class MemoizationTest < Test::Unit::TestCase
    class Foo
      extend Gluon::Memoization

      def initialize
        @count = 0
      end

      attr_reader :count

      def brackets(s)
        @count += 1
        "<#{s}>"
      end
      memoize :brackets
    end

    def setup
      @foo = Foo.new
    end

    def test_memoized
      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @foo.count)

      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @foo.count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(2, @foo.count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(2, @foo.count)
    end
  end

  class SingleMemoizationTest < Test::Unit::TestCase
    class Foo
      extend Forwardable

      def initialize
        @count = 0
      end

      attr_reader :count

      def brackets(s)
        @count += 1
        "<#{s}>"
      end
    end

    def setup
      @foo = Foo.new
    end

    def test_not_memoized
      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @foo.count)

      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(2, @foo.count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(3, @foo.count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(4, @foo.count)
    end

    def test_memoized
      @foo.extend Gluon::SingleMemoization
      @foo.memoize :brackets

      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @foo.count)

      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @foo.count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(2, @foo.count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(2, @foo.count)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
