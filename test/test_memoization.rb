#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'forwardable'
require 'gluon'
require 'test/unit'

module Gluon::Test
  class MemoizationTest < Test::Unit::TestCase
    class Foo
      extend Forwardable

      def initialize(test_case)
        @test_case = test_case
      end

      def_delegator :@test_case, :brackets
    end

    def brackets(s)
      @count += 1
      "<#{s}>"
    end

    def setup
      @count = 0
      @foo = Foo.new(self)
    end

    def test_not_memoized
      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @count)

      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(2, @count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(3, @count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(4, @count)
    end

    def test_memoized
      @foo.extend Gluon::Memoization
      @foo.memoize(:brackets)

      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @count)

      assert_equal('<foo>', @foo.brackets('foo'))
      assert_equal(1, @count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(2, @count)

      assert_equal('<bar>', @foo.brackets('bar'))
      assert_equal(2, @count)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
