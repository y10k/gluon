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
      gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$"
    end

    class Quux
      gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
        format('/%04d-%02d-%02d', year, mon, day)
      end
    end

    class RootId
      gluon_path_filter %r"^/$|^/(\d+)$" do |*args|
        id = args.shift
        args.empty? or raise ArgumentError, "too many arguments #{args.length} for 1"
        (id) ? format('/%d', id) : '/'
      end
    end

    def setup
      @url_map = Gluon::URLMap.new
    end

    def test_lookup
      @url_map.mount(Root, '/')
      @url_map.mount(Foo, '/foo')
      @url_map.mount(Bar, '/bar')
      @url_map.mount(Baz, '/bar')
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
      @url_map.mount(Baz, '/bar')
      @url_map.setup

      assert_nil(@url_map.lookup('/baz'))
      assert_nil(@url_map.lookup('/foo/bar'))
      assert_nil(@url_map.lookup('/bar/1975-11-19/halo'))
    end

    def test_class2path
      @url_map.mount(Root, '/')
      @url_map.mount(Foo, '/foo')
      @url_map.mount(Bar, '/bar')
      @url_map.setup

      assert_equal('/', @url_map.class2path(Root))
      assert_equal('/foo', @url_map.class2path(Foo))
      assert_equal('/bar', @url_map.class2path(Bar))
    end

    def test_class2path_not_found
      @url_map.mount(Foo, '/foo')
      @url_map.setup

      assert_nil(@url_map.class2path(Root))
    end

    def test_class2path_path_info
      @url_map.mount(Baz, '/baz')
      @url_map.mount(Quux, '/quux')
      @url_map.setup

      assert_equal('/baz/1975-11-19', @url_map.class2path(Baz, '/1975-11-19'))
      assert_equal('/quux/1975-11-19', @url_map.class2path(Quux, 1975, 11, 19))
    end

    def test_class2path_path_info_root
      @url_map.mount(Baz, '/')
      @url_map.setup

      assert_equal('/1975-11-19', @url_map.class2path(Baz, '/1975-11-19'))
    end

    def test_class2path_path_info_root2
      @url_map.mount(Quux, '/')
      @url_map.setup

      assert_equal('/1975-11-19', @url_map.class2path(Quux, 1975, 11, 19))
    end

    def test_class2path_path_info_root_id
      @url_map.mount(RootId, '/')
      @url_map.setup

      assert_equal('/', @url_map.class2path(RootId))
      assert_equal('/123', @url_map.class2path(RootId, 123))
    end

    def test_class2path_path_info_no_match
      @url_map.mount(Baz, '/baz')
      @url_map.setup

      assert_raise(ArgumentError) {
        @url_map.class2path(Baz)
      }
      assert_raise(ArgumentError) {
        @url_map.class2path(Baz, '/alice')
      }
      assert_raise(ArgumentError) {
        @url_map.class2path(Baz, '/2000')
      }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
