#!/usr/local/bin/ruby

require 'gluon'
require 'rack'
require 'test/unit'
module Gluon::Test
  class ErrorMapTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    class Root
    end

    class RootError < StandardError
    end

    class Foo
    end

    class FooError < RootError
    end

    class Bar
    end

    class BarError < FooError
    end

    class Baz
    end

    class BazError < RootError
    end

    def setup
      @err_map = Gluon::ErrorMap.new
    end

    def test_lookup
      @err_map.error_handler(RootError, Root)
      @err_map.error_handler(FooError, Foo)
      @err_map.error_handler(BarError, Bar)
      @err_map.error_handler(BazError, Baz)
      @err_map.setup
      assert_equal(Root, @err_map.lookup(RootError))
      assert_equal(Foo, @err_map.lookup(FooError))
      assert_equal(Bar, @err_map.lookup(BarError))
      assert_equal(Baz, @err_map.lookup(BazError))
    end

    def test_lookup_by_superclass
      @err_map.error_handler(RootError, Root)
      @err_map.error_handler(FooError, Foo)
      @err_map.setup
      assert_equal(Root, @err_map.lookup(RootError))
      assert_equal(Foo, @err_map.lookup(FooError))
      assert_equal(Foo, @err_map.lookup(BarError))
      assert_equal(Root, @err_map.lookup(BazError))
    end

    def test_lookup_not_found
      @err_map.error_handler(FooError, Foo)
      @err_map.error_handler(BarError, Bar)
      @err_map.error_handler(BazError, Baz)
      @err_map.setup
      assert_equal(nil, @err_map.lookup(RootError))
    end

    def test_lookup_empty
      @err_map.setup
      assert_equal(nil, @err_map.lookup(RootError))
      assert_equal(nil, @err_map.lookup(FooError))
      assert_equal(nil, @err_map.lookup(BarError))
      assert_equal(nil, @err_map.lookup(BazError))
    end

    def test_lookup_no_exception_error
      @err_map.error_handler(RootError, Root)
      @err_map.error_handler(FooError, Foo)
      @err_map.error_handler(BarError, Bar)
      @err_map.error_handler(BazError, Baz)
      @err_map.setup
      assert_raise(ArgumentError) {
        @err_map.lookup('FooError')
      }
    end

    def test_error_handler_no_exception_error
      assert_raise(ArgumentError) {
        @err_map.error_handler('FooError', Foo)
      }
      assert_raise(ArgumentError) {
        @err_map.error_handler(Object, Foo)
      }
    end

    def test_error_handler_no_page_type_error
      assert_raise(ArgumentError) {
        @err_map.error_handler(FooError, 'Foo')
      }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
