#!/usr/local/bin/ruby

require 'gluon/action'
require 'gluon/dispatcher'
require 'gluon/po'
require 'gluon/rs'
require 'rack'
require 'test/unit'

module Gluon::Test
  class ActionTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi',
                                       'SCRIPT_NAME' => '/bar.cgi')
      @req = Rack::Request.new(@env)
      @res = Rack::Response.new
      @dispatcher = Gluon::Dispatcher.new([])
      @c = Gluon::RequestResponseContext.new(@req, @res, @dispatcher)
    end

    def build_page(page_type)
      @page = page_type.new
      @action = Gluon::Action.new(@page, @c)
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
      def initialize
	@calls = []
      end

      attr_reader :calls

      def foo_action
	@calls << :foo_action
      end

      def bar_action
	@calls << :bar_action
      end
    end

    def test_apply_with_actions
      params = {
	'foo()' => nil,
	'bar' => nil,
	'foo.bar()' => nil
      }
      @env.update(Rack::MockRequest.env_for('http://foo:8080/bar.cgi',
					    'SCRIPT_NAME' => '/bar.cgi',
					    'QUERY_STRING' => Gluon::PresentationObject.query(params)))
      build_page(PageWithActions)

      count = 0
      @action.apply{
	count += 1
	assert_equal([ :foo_action ], @page.calls)
      }
      assert_equal(1, count)
    end
  end
end
