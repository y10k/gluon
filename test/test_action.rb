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
      include Gluon::Controller

      def page_get
      end
    end

    def test_apply
      build_page(SimplePage)

      count = 0
      @action.setup.apply{
        count += 1
      }

      assert_equal(1, count)
    end

    class PageWithPathArgs
      include Gluon::Controller

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
      @action.setup.apply(%w[ foo bar ]) {
        count += 1
      }

      assert_equal(1, count)
      assert_equal([ [ :page_get, %w[ foo bar ] ] ], @controller.calls)
    end

    class PageWithReqRes
      include Gluon::Controller

      attr_reader :c

      def page_get
      end
    end

    def test_apply_with_req_res
      build_page(PageWithReqRes)

      count = 0
      @action.setup.apply{
        count += 1
      }

      assert_equal(1, count)
      assert_equal(@c, @controller.c)
    end

    class PageWithHooks
      include Gluon::Controller

      def initialize
        @calls = []
        @c = nil
      end

      attr_reader :calls

      def page_around_hook
        @calls << :page_around_hook_in
        yield
        @calls << :page_around_hook_out
      end

      def page_start
        @calls << :page_start
      end

      # form value
      def foo=(value)
        @calls << :foo
        @foo = value
      end
      gluon_export :foo=, :accessor => true

      def page_get
        @calls << :page_get
        @c.validation = true
      end

      # form action
      def bar
        @calls << :bar
      end
      gluon_export :bar

      def page_end
        @calls << :page_end
      end
    end

    def test_apply_with_hooks
      params = {
        'foo' => 'apple',
        'bar()' => nil
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithHooks)

      count = 0
      @action.setup.apply{
        count += 1
        assert_equal([ :page_around_hook_in,
                       :page_start,
                       :foo,
                       :page_get,
                       :bar
                     ], @controller.calls)
      }

      assert_equal(1, count)
      assert_equal([ :page_around_hook_in,
                     :page_start,
                     :foo,
                     :page_get,
                     :bar,
                     :page_end,
                     :page_around_hook_out
                   ], @controller.calls)
    end

    class PageWithActions
      include Gluon::Controller

      def initialize
        @calls = []
        @c = nil
      end

      attr_reader :calls

      def page_get
        @calls << :page_get
        @c.validation = true
      end

      def foo
        @calls << :foo_action
      end
      gluon_export :foo

      def bar
        @calls << :bar_action
      end
      gluon_export :bar
    end

    def test_apply_with_actions
      params = {
        'foo()' => nil
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithActions)

      count = 0
      @action.setup.apply{
        count += 1
        assert_equal([ :page_get,
                       :foo_action
                     ], @controller.calls)
      }

      assert_equal(1, count)
    end

    class PageWithScalarParams
      include Gluon::Controller

      def page_start
        @foo = nil
        @bar = nil
      end

      gluon_accessor :foo
      gluon_accessor :bar

      def page_get
      end
    end

    def test_apply_with_scalar_params
      params = {
        'foo' => 'Apple'
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithScalarParams)

      count = 0
      @action.setup.apply{
        count += 1
        assert_equal('Apple', @controller.foo)
        assert_equal(nil, @controller.bar)
      }

      assert_equal(1, count)
    end

    class PageWithScalarParamCount
      include Gluon::Controller

      def initialize
        @calls = []
        @foo = nil
      end

      attr_reader :calls
      gluon_reader :foo

      def foo=(value)
        @calls << :foo
        @foo = value
      end
      gluon_export :foo=, :accessor => true

      def page_get
      end
    end

    def test_apply_with_scalar_param_set_once
      params = {
        'foo' => 'Apple'
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithScalarParamCount)

      count = 0
      work = proc{
        count += 1
        assert_equal([ :foo ], @controller.calls, 'set once')
        assert_equal('Apple', @controller.foo)
      }
      @action.setup.apply(&work)
      @action.setup.apply(&work)
      assert_equal(2, count)
    end

    class PageWithListParams
      include Gluon::Controller

      def page_start
        @foo = nil
        @bar = nil
        @baz = nil
      end

      gluon_accessor :foo
      gluon_accessor :bar
      gluon_accessor :baz

      def page_get
      end
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
      @action.setup.apply{
        count += 1
        assert_equal([], @controller.foo)
        assert_equal(%w[ apple ], @controller.bar)
        assert_equal(%w[ banana orange ], @controller.baz)
      }

      assert_equal(1, count)
    end

    class PageWithBooleanParams
      include Gluon::Controller

      def page_start
        @foo = true
        @bar = false
        @baz = false
      end

      gluon_accessor :foo
      gluon_accessor :bar
      gluon_accessor :baz

      def page_get
      end
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
      @action.setup.apply{
        count += 1
        assert_equal(false, @controller.foo)
        assert_equal(true,  @controller.bar)
        assert_equal(false, @controller.baz)
      }

      assert_equal(1, count)
    end

    class OtherPage
      include Gluon::Controller

      gluon_accessor :foo

      def self.foo=(value)
        raise 'not to reach.'
      end
    end

    class PageWithImportByClass
      include Gluon::Controller

      def other
        OtherPage
      end
      gluon_export :other, :accessor => true

      def page_get
      end
    end

    def test_apply_with_import_by_class
      params = {
        'other.foo' => 'Apple'
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithImportByClass)

      count = 0
      @action.setup.apply{
        count += 1
      }

      assert_equal(1, count)
    end

    class PageWithImportByObject
      include Gluon::Controller

      def page_start
        @other = OtherPage.new
      end

      gluon_reader :other

      def page_get
      end
    end

    def test_apply_with_import_by_object
      params = {
        'other.foo' => 'Apple'
      }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithImportByObject)

      count = 0
      @action.setup.apply{
        count += 1
        assert_equal('Apple', @controller.other.foo)
      }

      assert_equal(1, count)
    end

    class PageWithCacheKey
      include Gluon::Controller

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
      include Gluon::Controller

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

    def test_modified_not_defined
      build_page(SimplePage)
      assert_raise(NoMethodError) {
        @action.modified? :dummy_cache_tag
      }
    end

    class PageWithExplicitExport
      include Gluon::Controller

      def foo
      end
      gluon_export :foo

      def bar
      end

      gluon_accessor :baz
    end

    def test_export_implicit
      build_page(PageWithExplicitExport)
      assert((@action.export? 'foo'))
      assert(! (@action.export? 'bar'))
      assert((@action.export? 'baz'))
      assert((@action.export? 'baz='))
      for name in Object.instance_methods
        assert(! (@action.export? name.to_s))
      end
      Gluon::Action::RESERVED_WORDS.each_key do |name|
        assert(! (@action.export? name.to_s))
      end
    end

    class PageWithValidation
      include Gluon::Controller

      def initialize(validation)
        @validation = validation
        @calls = []
      end

      attr_reader :calls

      def page_get
        @c.validation = @validation ? true : false
      end

      def foo
        @calls << :foo_action
      end
      gluon_export :foo
    end

    def test_page_with_page_validation_ok
      params = { 'foo()' => nil }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithValidation, true)
      assert_equal([], @controller.calls)
      
      count = 0
      @action.setup.apply{
        assert_equal([ :foo_action ], @controller.calls)
        count += 1
      }

      assert_equal(1, count)
    end

    def test_page_with_page_validation_ng
      params = { 'foo()' => nil }
      @env['QUERY_STRING'] = Gluon::PresentationObject.query(params)
      build_page(PageWithValidation, false)
      assert_equal([], @controller.calls)
      
      count = 0
      @action.setup.apply{
        assert_equal([], @controller.calls)
        count += 1
      }

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
                     :used => {},
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
                     :used => {},
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
                     :used => {},
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
                     :used => {},
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
                     :used => {},
                     :branches => {
                       'bar' => {
                         :params => { 'baz' => 'banana', 'quux' => 'orange' },
                         :used => {},
                         :branches => {}
                       },
                       'aaa' => {
                         :params => {},
                         :used => {},
                         :branches => {
                           'bbb' => {
                             :params => { 'ccc' => 'pineapple' },
                             :used => {},
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
                     :used => {},
                     :branches => {
                       'foo[0]' => {
                         :params => { 'bar' => 'apple' },
                         :used => {},
                         :branches => {}
                       },
                       'foo[1]' => {
                         :params => { 'bar' => 'banana' },
                         :used => {},
                         :branches => {}
                       },
                       'foo[2]' => {
                         :params => { 'bar' => 'orange' },
                         :used => {},
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
                     :used => {},
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
