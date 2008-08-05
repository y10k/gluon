#!/usr/local/bin/ruby

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class URLMapTest < Test::Unit::TestCase
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

    def setup
      @url_map = Gluon::URLMap.new
    end

    def test_lookup
      @url_map.mount(Root, '/')
      @url_map.mount(Foo, '/foo')
      @url_map.mount(Bar, '/bar')
      @url_map.mount(Baz, '/bar', %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$")
      @url_map.setup

      assert_equal([ Root, '/', [] ], @url_map.lookup('/'))
      assert_equal([ Foo, nil, [] ], @url_map.lookup('/foo'))
      assert_equal([ Bar, nil, [] ], @url_map.lookup('/bar'))
      assert_equal([ Baz, '/1975-11-19', %w[ 1975 11 19 ] ],
                   @url_map.lookup('/bar/1975-11-19'))
    end

    def test_lookup_not_found
      @url_map.mount(Root, '/')
      @url_map.mount(Foo, '/foo')
      @url_map.mount(Bar, '/bar')
      @url_map.mount(Baz, '/bar', %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$")
      @url_map.setup

      assert_nil(@url_map.lookup('/baz'))
      assert_nil(@url_map.lookup('/foo/bar'))
      assert_nil(@url_map.lookup('/bar/1975-11-19/halo'))
    end

    def test_class2path
      @url_map.mount(Root, '/')
      @url_map.mount(Foo, '/foo')
      @url_map.mount(Bar, '/bar')
      @url_map.mount(Baz, '/bar', %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$")
      @url_map.setup

      assert_equal('/', @url_map.class2path(Root))
      assert_equal('/foo', @url_map.class2path(Foo))
      assert_equal('/bar', @url_map.class2path(Bar))
      assert_equal('/bar', @url_map.class2path(Baz))
    end

    def test_class2path_not_found
      @url_map.mount(Foo, '/foo')
      @url_map.setup

      assert_nil(@url_map.class2path(Root))
    end

    class PathFilterRoot
      gluon_path_filter %r"^/root$"
    end

    class PathFilterFoo < PathFilterRoot
      gluon_path_filter %r"^/foo$"
    end

    class PathFilterBar < PathFilterRoot
    end

    class PathFilterBaz
    end

    def test_find_path_filter
      assert_equal(%r"^/root$", Gluon::URLMap.find_path_filter(PathFilterRoot))
      assert_equal(%r"^/foo$", Gluon::URLMap.find_path_filter(PathFilterFoo))
      assert_equal(%r"^/root$", Gluon::URLMap.find_path_filter(PathFilterBar))
      assert_equal(nil, Gluon::URLMap.find_path_filter(PathFilterBaz))
    end

    def test_lookup_with_default_path_filter
      @url_map.mount(PathFilterRoot, '/')
      @url_map.mount(PathFilterFoo, '/test')
      @url_map.mount(PathFilterBar, '/test')
      @url_map.mount(PathFilterBaz, '/test')
      @url_map.setup

      assert_equal([ PathFilterRoot, '/root', [] ], @url_map.lookup('/root'))
      assert_equal(nil, @url_map.lookup('/'))

      assert_equal([ PathFilterFoo, '/foo', [] ], @url_map.lookup('/test/foo'))
      assert_equal([ PathFilterBar, '/root', [] ], @url_map.lookup('/test/root'))
      assert_equal([ PathFilterBaz, nil, [] ], @url_map.lookup('/test'))
      assert_equal(nil, @url_map.lookup('/test/no_mount'))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
