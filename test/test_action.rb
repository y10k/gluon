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

    def build_page(page_type, *args)
      @controller = page_type.new(*args)
      params, funcs = Gluon::Action.parse(@c.req.params)
      @action = Gluon::Action.new(@controller, @c, params, funcs)
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

    class PageWithPathArgs
      def initialize
        @calls = []
      end

      attr_reader :calls

      def page_get(*args)
        @calls << [ :page_get, args ]
      end
    end

    def test_apply_with_path_args
      build_page(PageWithPathArgs)

      count = 0
      work = proc{ count += 1 }
      @action.setup.apply(work, %w[ foo bar ])

      assert_equal(1, count)
      assert_equal([ [ :page_get, %w[ foo bar ] ] ], @controller.calls)
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

      def page_get
        @calls << :page_get
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
        assert_equal([ :page_hook_in,
                       :page_start,
                       :page_get
                     ], @controller.calls)
      }
      @action.setup.apply(work)

      assert_equal(1, count)
      assert_equal([ :page_hook_in,
                     :page_start,
                     :page_get,
                     :page_end,
                     :page_hook_out
                   ], @controller.calls)
    end

    class PageWithActions
      def page_start
        @calls = []
      end

      attr_reader :calls

      def page_get
        @calls << :page_get
      end

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
        assert_equal([ :page_get,
                       :foo_action
                     ], @controller.calls)
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
        assert_equal(nil, @controller.bar)
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    def test_apply_with_no_set_params
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
        assert_equal(nil, @controller.foo)
        assert_equal(nil, @controller.bar)
      }
      @action.setup.apply(work, [], true)

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

    class OtherPage
      attr_accessor :foo

      def self.foo=(value)
        raise 'not to reach.'
      end
    end

    class PageWithImportByClass
      def other
        OtherPage
      end
    end

    def test_apply_with_import_by_class
      params = {
        'other.foo' => 'Apple'
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithImportByClass)

      count = 0
      work = proc{
        count += 1
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    class PageWithImportByObject
      def page_start
        @other = OtherPage.new
      end

      attr_reader :other
    end

    def test_apply_with_import_by_object
      params = {
        'other.foo' => 'Apple'
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithImportByObject)

      count = 0
      work = proc{
        count += 1
        assert_equal('Apple', @controller.other.foo)
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

    class PageWithImplicitExport
      attr_accessor :c

      def page_hook
        yield
      end

      def page_start
      end

      def page_end
      end

      def __view__
        'no_view.rhtml'
      end

      def __default_view__
        'no_view.rhtml'
      end

      def __cache_key__
        :dummy_cache_tag
      end

      def __if_modified__(cache_tag)
        true
      end

      def foo
      end

      def bar
      end

      def baz
      end
    end

    def test_export_implicit
      build_page(PageWithImplicitExport)
      assert_equal(true, (@action.export? 'foo'))
      assert_equal(true, (@action.export? 'bar'))
      assert_equal(true, (@action.export? 'baz'))
      for name in Object.instance_methods
        assert_equal(false, (@action.export? name.to_s))
      end
      Gluon::Action::RESERVED_WORDS.each_key do |name|
        assert_equal(false, (@action.export? name.to_s))
      end
    end

    class PageWithExplicitExport
      attr_accessor :c

      def page_hook
        yield
      end

      def page_start
      end

      def page_end
      end

      def __view__
        'no_view.rhtml'
      end

      def __default_view__
        'no_view.rhtml'
      end

      def __cache_key__
        :dummy_cache_tag
      end

      def __if_modified__(cache_tag)
        true
      end

      def __export__(name)
        case (name)
        when 'foo'
          true
        when 'bar'
          false
        when 'baz'
          true
        else
          false
        end
      end

      def foo
      end

      def bar
      end

      def baz
      end
    end

    def test_export_implicit
      build_page(PageWithExplicitExport)
      assert_equal(true, (@action.export? 'foo'))
      assert_equal(false, (@action.export? 'bar'))
      assert_equal(true, (@action.export? 'baz'))
      for name in Object.instance_methods
        assert_equal(false, (@action.export? name.to_s))
      end
      Gluon::Action::RESERVED_WORDS.each_key do |name|
        assert_equal(false, (@action.export? name.to_s))
      end
    end

    class PageWithPageCheck
      def initialize(check_stat)
        @check_stat = check_stat
        @calls = []
      end

      attr_reader :calls

      def page_check
        @check_stat
      end

      def foo
        @calls << :foo_action
      end
    end

    def test_page_with_page_check_ok
      params = { 'foo()' => nil }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithPageCheck, true)
      assert_equal(true, @controller.page_check)
      assert_equal([], @controller.calls)
      
      count = 0
      work = proc{
        assert_equal([ :foo_action ], @controller.calls)
        count += 1
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end

    def test_page_with_page_check_ng
      params = { 'foo()' => nil }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithPageCheck, false)
      assert_equal(false, @controller.page_check)
      assert_equal([], @controller.calls)
      
      count = 0
      work = proc{
        assert_equal([], @controller.calls)
        count += 1
      }
      @action.setup.apply(work)

      assert_equal(1, count)
    end
  end

  class ActionParserTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def test_parse_params_simple_value
      req_params = {
        'foo' => 'apple',
        'bar' => %w[ banana orange pineapple ]
      }

      assert_equal({ :params => {
                       'foo' => 'apple',
                       'bar' => 'banana'
                     },
                     :branches => {}
                   },
                   Gluon::Action.parse_params(req_params))
    end

    def test_parse_params_scalar_value
      req_params = {
        'foo' => 'apple',
        'foo@type' => 'scalar',
        'bar' => %w[ banana orange pineapple ],
        'bar@type' => 'scalar'
      }

      assert_equal({ :params => {
                       'foo' => 'apple',
                       'bar' => 'banana'
                     },
                     :branches => {}
                   },
                   Gluon::Action.parse_params(req_params))
    end

    def test_parse_params_list_value
      req_params = {
        'foo' => 'apple',
        'foo@type' => 'list',
        'bar' => %w[ banana orange pineapple ],
        'bar@type' => 'list',
        'baz@type' => 'list'
      }

      assert_equal({ :params => {
                       'foo' => %w[ apple ],
                       'bar' => %w[ banana orange pineapple ],
                       'baz' => []
                     },
                     :branches => {}
                   },
                   Gluon::Action.parse_params(req_params))
    end

    def test_parse_params_bool_value
      req_params = {
        'foo' => 'true',
        'foo@type' => 'bool',
        'bar@type' => 'bool'
      }

      assert_equal({ :params => {
                       'foo' => true,
                       'bar' => false,
                     },
                     :branches => {}
                   },
                   Gluon::Action.parse_params(req_params))
    end

    def test_parse_params_nested
      req_params = {
        'foo' => 'apple',
        'bar.baz' => 'banana',
        'bar.quux' => 'orange',
        'aaa.bbb.ccc' => 'pineapple'
      }

      assert_equal({ :params => { 'foo' => 'apple' },
                     :branches => {
                       'bar' => {
                         :params => { 'baz' => 'banana', 'quux' => 'orange' },
                         :branches => {}
                       },
                       'aaa' => {
                         :params => {},
                         :branches => {
                           'bbb' => {
                             :params => { 'ccc' => 'pineapple' },
                             :branches => {}
                           }
                         }
                       }
                     }
                   },
                   Gluon::Action.parse_params(req_params))
    end

    def test_parse_params_array
      req_params = {
        'foo[0].bar' => 'apple',
        'foo[1].bar' => 'banana',
        'foo[2].bar' => 'orange',
        'foo[3]' => 'pineapple' # ignored
      }

      assert_equal({ :params => {},
                     :branches => {
                       'foo[0]' => {
                         :params => { 'bar' => 'apple' },
                         :branches => {}
                       },
                       'foo[1]' => {
                         :params => { 'bar' => 'banana' },
                         :branches => {}
                       },
                       'foo[2]' => {
                         :params => { 'bar' => 'orange' },
                         :branches => {}
                       }
                     }
                   },
                   Gluon::Action.parse_params(req_params))
    end

    def test_parse_params_ignored_function
      req_params = {
        'foo()' => nil
      }

      assert_equal({ :params => {},
                     :branches => {}
                   },
                   Gluon::Action.parse_params(req_params))
    end

    def test_parse_funcs_simple_function
      req_params = {
        'foo()' => nil,
        'bar()' => 'HALO'
      }

      assert_equal({ '' => { 'foo' => true, 'bar' => true } },
                   Gluon::Action.parse_funcs(req_params))
    end

    def test_parse_funcs_nested
      req_params = {
        'foo()' => nil,
        'bar.baz()' => nil,
        'bar.quux()' => nil,
        'aaa.bbb.ccc()' => nil
      }

      assert_equal({ '' => { 'foo' => true },
                     'bar.' => { 'baz' => true, 'quux' => true },
                     'aaa.bbb.' => { 'ccc' => true }
                   },
                   Gluon::Action.parse_funcs(req_params))
    end

    def test_parse_funcs_ignored_params
      req_params = {
        'foo' => 'apple',
        'bar' => 'banana',
        'bar@type' => 'list',
        'baz@type' => 'bool'
      }

      assert_equal({}, Gluon::Action.parse_funcs(req_params))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
