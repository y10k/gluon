#!/usr/local/bin/ruby

require 'gluon/dispatcher'
require 'rack'
require 'test/unit'

module Gluon::Test
  class DispatcherTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    class Root
    end

    class Foo
    end

    class Bar
    end

    class Baz
    end

    def test_look_up
      url_map = [
	[ '/', Root ],
	[ '/foo', Foo ],
	[ '/foo/bar', Bar ],
	[ '/baz', Baz ]
      ]
      dispatcher = Gluon::Dispatcher.new(url_map)

      assert_equal([ Root, '' ],            dispatcher.look_up(''))
      assert_equal([ Root, '/' ],           dispatcher.look_up('/'))
      assert_equal([ Root, '/index.html' ], dispatcher.look_up('/index.html'))

      assert_equal([ Foo, '' ],           dispatcher.look_up('/foo'))
      assert_equal([ Foo, '/' ],          dispatcher.look_up('/foo/'))
      assert_equal([ Foo, '/something' ], dispatcher.look_up('/foo/something'))

      assert_equal([ Bar, '' ],           dispatcher.look_up('/foo/bar'))
      assert_equal([ Bar, '/' ],          dispatcher.look_up('/foo/bar/'))
      assert_equal([ Bar, '/something' ], dispatcher.look_up('/foo/bar/something'))

      assert_equal([ Baz, '' ],           dispatcher.look_up('/baz'))
      assert_equal([ Baz, '/' ],          dispatcher.look_up('/baz/'))
      assert_equal([ Baz, '/something' ], dispatcher.look_up('/baz/something'))
    end

    def test_not_found
      url_map = [
	[ '/foo', Foo ]
      ]
      dispatcher = Gluon::Dispatcher.new(url_map)

      assert_equal(nil, dispatcher.look_up(''))
      assert_equal(nil, dispatcher.look_up('/'))
      assert_equal(nil, dispatcher.look_up('/index.html'))

      assert_equal([ Foo, '' ],           dispatcher.look_up('/foo'))
      assert_equal([ Foo, '/' ],          dispatcher.look_up('/foo/'))
      assert_equal([ Foo, '/something' ], dispatcher.look_up('/foo/something'))

      assert_equal(nil, dispatcher.look_up('/bar'))
      assert_equal(nil, dispatcher.look_up('/bar/'))
      assert_equal(nil, dispatcher.look_up('/bar/something'))
    end
  end
end

