#!/usr/local/bin/ruby

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class ActionTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @mock = Gluon::Mock.new
      @c = @mock.new_request(@env)
    end

    def build_page(page_type)
      @controller = page_type.new
      @action = Gluon::Action.new(@controller, @c)
    end
    private :build_page

    class SimplePage
    end

    def test_apply
      build_page(SimplePage)

      count = 0
      work = proc{ count += 1 }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    class PageWithReqRes
      attr_accessor :c
    end

    def test_apply_with_req_res
      build_page(PageWithReqRes)

      count = 0
      work = proc{
	count += 1
      }
      @action.setup.apply(work)

      assert_equal(1, count)
      assert_equal(@c, @controller.c)
    end

    class PageWithHooks
      def initialize
	@calls = []
      end

      attr_reader :calls

      def page_hook
	@calls << :page_hook_in
	yield
	@calls << :page_hook_out
      end

      def page_start
	@calls << :page_start
      end

      def page_end
	@calls << :page_end
      end
    end

    def test_apply_with_hooks
      build_page(PageWithHooks)

      count = 0
      work = proc{
	count += 1
	assert_equal([ :page_hook_in, :page_start ], @controller.calls)
      }
      @action.setup.apply(work)

      assert_equal(1, count)
      assert_equal([ :page_hook_in, :page_start, :page_end, :page_hook_out ], @controller.calls)
    end

    class PageWithActions
      def page_start
	@calls = []
      end

      attr_reader :calls

      def foo
	@calls << :foo_action
      end

      def bar
	@calls << :bar_action
      end
    end

    def test_apply_with_actions
      params = {
	'foo()' => nil,
	'bar' => nil,
	#'foo.bar()' => nil
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithActions)

      count = 0
      work = proc{
	count += 1
	assert_equal([ :foo_action ], @controller.calls)
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    class PageWithScalarParams
      def page_start
	@foo = nil
	@bar = nil
      end

      attr_accessor :foo
      attr_accessor :bar
    end

    def test_apply_with_scalar_params
      params = {
	'foo' => 'Apple',
	#'bar()' => 'Banana',
	'foo.bar' => 'Orange'
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithScalarParams)

      count = 0
      work = proc{
	count += 1
	assert_equal('Apple', @controller.foo)
	assert_equal(nil,     @controller.bar)
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    class PageWithListParams
      def page_start
        @foo = nil
        @bar = nil
        @baz = nil
      end

      attr_accessor :foo
      attr_accessor :bar
      attr_accessor :baz
    end

    def test_apply_with_list_params
      params = {
        'foo@type' => 'list',
        'bar@type' => 'list',
        'baz@type' => 'list',
        'bar' => 'apple',
        'baz' => %w[ banana orange ]
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithListParams)

      count = 0
      work = proc{
        count += 1
        assert_equal([], @controller.foo)
        assert_equal(%w[ apple ], @controller.bar)
        assert_equal(%w[ banana orange ], @controller.baz)
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    class PageWithBooleanParams
      def page_start
	@foo = true
	@bar = false
	@baz = false
      end

      attr_accessor :foo
      attr_accessor :bar
      attr_accessor :baz
    end

    def test_apply_with_boolean_params
      params = {
	'foo@type' => 'bool',
	'bar@type' => 'bool',
	'baz@type' => 'bool',
	'bar' => ''
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithBooleanParams)

      count = 0
      work = proc{
	count += 1
	assert_equal(false, @controller.foo)
	assert_equal(true,  @controller.bar)
	assert_equal(false, @controller.baz)
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    class PageWithCacheKey
      def __cache_key__
	:dummy_cache_key
      end
    end

    def test_cache_key
      build_page(PageWithCacheKey)
      assert_equal(:dummy_cache_key, @action.cache_key)
    end

    def test_cache_key_default
      build_page(SimplePage)
      assert_nil(@action.cache_key)
    end

    class PageWithIfModified
      def __if_modified__(cache_tag)
	case (cache_tag)
	when :foo
	  true
	when :bar
	  false
	else
	  raise "unexpected tag: #{cache_tag}"
	end
      end
    end

    def test_modified
      build_page(PageWithIfModified)
      assert_equal(true, (@action.modified? :foo))
      assert_equal(false, (@action.modified? :bar))
    end

    def test_modified_default
      build_page(SimplePage)
      assert_equal(true, (@action.modified? :dummy_cache_tag))
    end
  end

  class ActionParameterScannerTest < Test::Unit::TestCase
    class Foo
      attr_accessor :foo
      attr_accessor :bar
    end

    class Bar
      attr_accessor :baz
    end

    def test_each
      foo = Foo.new
      bar = Bar.new
      foo.bar = bar

      params = [
	[ 'foo', 'apple' ],
	[ 'bar.baz', 'banana' ]
      ]

      param_scan = Gluon::Action::ParameterScanner.new('', foo, params)
      assert_equal([ [ foo, 'foo', 'foo', 'apple', ],
		     [ bar, 'bar.baz', 'baz', 'banana' ]
		   ], param_scan.to_a)
    end

    def test_each_with_array
      foo = Foo.new
      bar = [ Bar.new, Bar.new, Bar.new ]
      foo.bar = bar

      params = [
	[ 'bar[0].baz', 'apple' ],
	[ 'bar[1].baz', 'banana' ],
	[ 'bar[2].baz', 'orange' ]
      ]

      param_scan = Gluon::Action::ParameterScanner.new('', foo, params)
      assert_equal([ [ bar[0], 'bar[0].baz', 'baz', 'apple', ],
		     [ bar[1], 'bar[1].baz', 'baz', 'banana', ],
		     [ bar[2], 'bar[2].baz', 'baz', 'orange', ]
		   ], param_scan.to_a)
    end
  end
end
