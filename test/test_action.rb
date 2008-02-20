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
      @req = Rack::Request.new(@env)
      @res = Rack::Response.new
      @session = Object.new	# dummy
      @dispatcher = Gluon::Dispatcher.new([])
      @c = Gluon::RequestResponseContext.new(@req, @res, @session, @dispatcher)
      @plugin = {}
    end

    def build_page(page_type)
      @page = page_type.new
      @action = Gluon::Action.new(@page, @c, @plugin)
    end
    private :build_page

    class SimplePage
    end

    def test_apply
      build_page(SimplePage)

      count = 0
      @action.apply{
	count += 1
      }

      assert_equal(1, count)
    end

    class PageWithReqRes
      attr_accessor :c
    end

    def test_apply_with_req_res
      build_page(PageWithReqRes)

      count = 0
      @action.apply{
	count += 1
      }

      assert_equal(1, count)
      assert_equal(@c, @page.c)
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
      @action.apply{
	count += 1
	assert_equal([ :page_hook_in, :page_start ], @page.calls)
      }

      assert_equal(1, count)
      assert_equal([ :page_hook_in, :page_start, :page_end, :page_hook_out ], @page.calls)
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
      @action.apply{
	count += 1
	assert_equal([ :foo_action ], @page.calls)
      }
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
      @action.apply{
	count += 1
	assert_equal('Apple', @page.foo)
	assert_equal(nil,     @page.bar)
      }
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
      @action.apply{
        count += 1
        assert_equal([], @page.foo)
        assert_equal(%w[ apple ], @page.bar)
        assert_equal(%w[ banana orange ], @page.baz)
      }
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
      @action.apply{
	count += 1
	assert_equal(false, @page.foo)
	assert_equal(true,  @page.bar)
	assert_equal(false, @page.baz)
      }
      assert_equal(1, count)
    end

    class PageWithPlugin
      attr_accessor :foo
      attr_accessor :bar
    end

    def test_apply_with_plugin
      @plugin[:foo] = 'test of plugin'
      build_page(PageWithPlugin)

      count = 0
      @action.apply{
	count += 1
	assert_equal('test of plugin', @page.foo)
      }
      assert_equal(1, count)
    end

    def test_plugin_override_params
      @plugin[:foo] = 'test of plugin'
      params = { 'foo' => 'test of parameter'}
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithPlugin)

      count = 0
      @action.apply{
	count += 1
	assert_equal('test of plugin', @page.foo, 'prior plugin')
      }
      assert_equal(1, count)
    end
  end

  class ActionParameterScanner < Test::Unit::TestCase
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
