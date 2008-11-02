#!/usr/local/bin/ruby

require 'fileutils'
require 'gluon'
require 'rack'

module Gluon::Test
  module ViewTestHelper
    # for ident(1)
    CVS_ID = '$Id$'

    VIEW_DIR = 'view'

    class AnotherPage
      include Gluon::Controller

      gluon_path_filter %r"^/([A-Za-z_]+)/([0-9])+$"

      def page_start(name, id)
      end
    end

    def setup
      @view_dir = VIEW_DIR
      @renderer = Gluon::ViewRenderer.new(@view_dir)
      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @mock = Gluon::Mock.new(:url_map => {
                                AnotherPage => '/another_page' },
                              :view_dir => @view_dir)

      FileUtils.rm_rf(@view_dir) # for debug
      FileUtils.mkdir_p(@view_dir)
    end

    def teardown
      FileUtils.rm_rf(@view_dir) unless $DEBUG
    end

    def build_page(page_type)
      v = target_view_module()
      page_type = Class.new(page_type)
      page_type.class_eval{ include v }
      @c = @mock.new_request(@env)
      @params, @funcs = Gluon::Action.parse(@c.req.params)
      @controller = page_type.new
      @controller.c = @c
      @action = Gluon::Action.new(@controller, @c, @params, @funcs)
      @po = Gluon::PresentationObject.new(@controller, @c, @action)
    end
    private :build_page

    def render_page(view_script, filename=nil)
      unless (filename) then
        filename = @c.default_template(@controller) + target_view_module::SUFFIX
      end
      FileUtils.mkdir_p(File.dirname(filename))
      File.open("#{filename}.tmp", 'w') {|out|
        out << view_script
      }
      File.rename("#{filename}.tmp", filename) # to change i-node
      @controller.page_render(@po)
    end
    private :render_page

    module Syntax
    end
    extend Syntax

    def self.included(other_module)
      other_module.extend(Syntax)
      super
    end

    module Caller
      def caller_frame(at)
        if (/^(.+?):(\d+)(?::in `(.*)')?/ =~ caller[at]) then
          file = $1
          line = $2.to_i
          method = $3
          return file, line, method
        end

        nil
      end
      module_function :caller_frame
    end

    module Syntax
      def def_test_view(name, page_type, expected)
        file, line, = Caller.caller_frame(1)
        module_eval(<<-EOF, "#{file}:#{line} -> #{__FILE__}", __LINE__ + 1)
          def view_expected_#{name}
            #{expected.dump}
          end
  
          def test_#{name}
            build_page(#{page_type})
            assert_equal(view_expected_#{name},
                         render_page(view_template_#{name}))
          end
        EOF
      end
    end

    def assert_attrs_advice_hash(page_type, method, start_with, expr)
      anon_page_type = Class.new(page_type) {
        gluon_advice method, :attrs => {
          'foo' => 'Apple',
          'bar' => 'Banana',
          'baz' => true
        }
      }
      build_page(anon_page_type)
      result = render_page(expr)
      assert_match(start_with, result)
      assert_match(/ foo="Apple"/, result)
      assert_match(/ bar="Banana"/, result)
      assert_match(/ baz="baz"/, result)
    end
    private :assert_attrs_advice_hash

    def assert_attrs_advice_proc(page_type, method, start_with, expr)
      anon_page_type = Class.new(page_type) {
        gluon_advice method, :attrs => proc{
          { 'foo' => 'Apple', 'bar' => 'Banana', 'baz' => true }
        }
      }
      build_page(anon_page_type)
      result = render_page(expr)
      assert_match(start_with, result)
      assert_match(/ foo="Apple"/, result)
      assert_match(/ bar="Banana"/, result)
      assert_match(/ baz="baz"/, result)
    end
    private :assert_attrs_advice_proc

    def assert_attrs_advice_method(page_type, method, start_with, expr)
      anon_page_type = Class.new(page_type) {
        define_method(:controller_attrs) {
          return 'foo' => 'Apple', 'bar' => 'Banana', 'baz' => true
        }
        gluon_advice method, :attrs => instance_method(:controller_attrs)
      }
      build_page(anon_page_type)
      result = render_page(expr)
      assert_match(start_with, result)
      assert_match(/ foo="Apple"/, result)
      assert_match(/ bar="Banana"/, result)
      assert_match(/ baz="baz"/, result)
    end
    private :assert_attrs_advice_method

    def assert_attrs_embedded(page_type, method, start_with, expr)
      build_page(page_type)
      result = render_page(expr)
      assert_match(start_with, result)
      assert_match(/ foo="Apple"/, result)
      assert_match(/ bar="Banana"/, result)
      assert_match(/ baz="baz"/, result)
    end
    private :assert_attrs_embedded

    def assert_attrs_advice_over_embedded(page_type, method, start_with, expr)
      anon_page_type = Class.new(page_type) {
        gluon_advice method, :attrs => { 'foo' => 'Orange', 'baz' => false }
      }
      build_page(anon_page_type)
      result = render_page(expr)
      assert_match(start_with, result)
      assert_no_match(/ foo="Apple"/, result)
      assert_match(/ foo="Orange"/, result)
      assert_match(/ bar="Banana"/, result)
      assert_no_match(/ baz="baz"/, result)
    end
    private :assert_attrs_advice_over_embedded

    module Syntax
      def def_test_attrs(name, page_type, method, start_with)
        file, line, = Caller.caller_frame(1)
        args = "#{page_type}"
        args << ", #{method.to_sym.inspect}"
        args << ", /^\#{Regexp.quote(#{start_with.dump})}/"
        module_eval(<<-EOF, "#{__FILE__},test_#{name}_attrs(#{line})", __LINE__ + 1)
          def test_#{name}_attrs_advice_hash
            assert_attrs_advice_hash(#{args}, view_template_#{name})
          end
          def test_#{name}_attrs_advice_proc
            assert_attrs_advice_proc(#{args}, view_template_#{name})
          end
          def test_#{name}_attrs_advice_method
            assert_attrs_advice_method(#{args}, view_template_#{name})
          end
          def test_#{name}_attrs_embedded
            assert_attrs_embedded(#{args}, view_template_#{name}_embedded_attrs)
          end
          def test_#{name}_attrs_advice_over_embedded
            assert_attrs_advice_over_embedded(#{args}, view_template_#{name}_embedded_attrs)
          end
        EOF
      end
    end

    class SimplePage
      include Gluon::Controller
    end

    def_test_view :simple, SimplePage, "Hello world.\n"

    class PageForValue < SimplePage
      def foo
        'Hello world.'
      end
      gluon_advice :foo, :type => :value

      def bar
        '&<>" foo'
      end
      gluon_advice :bar, :type => :value, :escape => true

      def baz
        '&<>" foo'
      end
      gluon_advice :baz, :type => :value, :escape => false
    end

    def_test_view :value, PageForValue, 'Hello world.'
    def_test_view :value_escape, PageForValue, '&amp;&lt;&gt;&quot; foo'
    def_test_view :value_no_escape, PageForValue, '&<>" foo'
    def_test_view :value_content_ignored, PageForValue, 'Hello world.'

    class PageForCond < SimplePage
      def foo?
        true
      end
      gluon_advice :foo?, :type => :cond

      def bar?
        false
      end
      gluon_advice :bar?, :type => :cond
    end

    def_test_view :cond_true, PageForCond, 'should be picked up.'
    def_test_view :cond_false, PageForCond, ''

    class PageForForeach < SimplePage
      def foo
        %w[ apple banana orange ]
      end
      gluon_advice :foo, :type => :foreach

      def bar
        []
      end
      gluon_advice :bar, :type => :foreach
    end

    def_test_view :foreach, PageForForeach, '[apple][banana][orange]'
    def_test_view :foreach_empty_list, PageForForeach, ''

    class PageForLink < SimplePage
      def foo
        return '/Foo', :text => 'foo'
      end
      gluon_advice :foo, :type => :link

      def bar
        return AnotherPage, :path_info => '/foo/123'
      end
      gluon_advice :bar, :type => :link
    end

    def_test_view :link, PageForLink,
      '<a href="/Foo">foo</a>'
    def_test_view :link_content, PageForLink,
      '<a href="/Foo">should be picked up.</a>'
    def_test_view :link_class, PageForLink,
      '<a href="/bar.cgi/another_page/foo/123">/bar.cgi/another_page/foo/123</a>'
    def_test_attrs :link, PageForLink, :foo, '<a '

    class PageForAction < SimplePage
      def foo
      end
      gluon_export :foo, :type => :action

      def bar
      end
      gluon_export :bar, :type => :action, :text => 'Action'
    end

    def_test_view :action, PageForAction,
      '<a href="/bar.cgi?foo%28%29">foo</a>'
    def_test_view :action_text, PageForAction,
      '<a href="/bar.cgi?bar%28%29">Action</a>'
    def_test_view :action_content, PageForAction,
      '<a href="/bar.cgi?bar%28%29">should be picked up.</a>'
    def_test_attrs :action, PageForAction, :foo, '<a '

    class PageForFrame < SimplePage
      def foo
        '/Foo'
      end
      gluon_advice :foo, :type => :frame
    end

    def_test_view :frame, PageForFrame,
      '<frame src="/Foo" />'
    def_test_view :frame_content_ignored, PageForFrame,
      '<frame src="/Foo" />'
    def_test_attrs :frame, PageForFrame, :foo, '<frame '

    class PageForImport < SimplePage
      class Foo
        include Gluon::Controller

        def page_import         # checked by Gluon::Action
        end

        def page_render(po)
          'should be picked up.'
        end
      end

      class Bar
        include Gluon::Controller

        def page_import         # checked by Gluon::Action
        end

        def page_render(po)
          '[' + po.content + ']'
        end
      end

      class Baz
        include Gluon::Controller

        def page_import         # checked by Gluon::Action
        end

        def page_render(po)
          '[' + po.content{|out| out << 'should be picked up.' } + ']'
        end
      end

      def foo
        Foo.new
      end
      gluon_advice :foo, :type => :import

      def bar
        Bar.new
      end
      gluon_advice :bar, :type => :import

      def baz
        Baz.new
      end
      gluon_advice :baz, :type => :import
    end

    def_test_view :import, PageForImport, '[should be picked up.]'
    def_test_view :import_content, PageForImport, '[should be picked up.]'
    def_test_view :import_content_default, PageForImport, '[should be picked up.]'

    def test_import_content_not_defined
      build_page(PageForImport)
      assert_raise(RuntimeError) {
        render_page(view_template_import_content_not_defined)
      }
    end

    class PageForText < SimplePage
      def initialize
        @foo = nil
        @bar = 'should be picked up.'
      end

      gluon_export_accessor :foo, :type => :text
      gluon_export_accessor :bar, :type => :text
    end

    def_test_view :text, PageForText,
      '<input type="text" name="foo" value="" />'
    def_test_view :text_value, PageForText,
      '<input type="text" name="bar" value="should be picked up." />'
    def_test_view :text_content_ignored, PageForText,
      '<input type="text" name="foo" value="" />'
    def_test_attrs :text, PageForText, :foo, '<input '

    class PageForPassword < SimplePage
      def initialize
        @foo = nil
        @bar = 'should be picked up.'
      end

      gluon_export_accessor :foo, :type => :password
      gluon_export_accessor :bar, :type => :password
    end

    def_test_view :password, PageForPassword,
      '<input type="password" name="foo" value="" />'
    def_test_view :password_value, PageForPassword,
      '<input type="password" name="bar" value="should be picked up." />'
    def_test_view :password_content_ignored, PageForPassword,
      '<input type="password" name="foo" value="" />'
    def_test_attrs :password, PageForPassword, :foo, '<input '

    class PageForSubmit < SimplePage
      def foo
      end
      gluon_export :foo, :type => :submit

      def bar
      end
      gluon_export :bar, :type => :submit, :value => 'should be picked up.'
    end

    def_test_view :submit, PageForSubmit,
      '<input type="submit" name="foo()" />'
    def_test_view :submit_value, PageForSubmit,
      '<input type="submit" name="bar()" value="should be picked up." />'
    def_test_view :submit_content_ignored, PageForSubmit,
      '<input type="submit" name="foo()" />'
    def_test_attrs :submit, PageForSubmit, :foo, '<input '

    class PageForHidden < SimplePage
      def initialize
        @foo = nil
        @bar = 'Hello world.'
      end

      gluon_export_accessor :foo, :type => :hidden
      gluon_export_accessor :bar, :type => :hidden
    end

    def_test_view :hidden, PageForHidden,
      '<input type="hidden" name="foo" value="" />'
    def_test_view :hidden_value, PageForHidden,
      '<input type="hidden" name="bar" value="Hello world." />'
    def_test_view :hidden_content_ignored, PageForHidden,
      '<input type="hidden" name="foo" value="" />'
    def_test_attrs :hidden, PageForHidden, :foo, '<input '

    class PageForCheckbox < SimplePage
      def initialize
        @foo = false
        @bar = true
      end

      gluon_export_accessor :foo, :type => :checkbox
      gluon_export_accessor :bar, :type => :checkbox
    end

    def_test_view :checkbox, PageForCheckbox,
      '<input type="hidden" name="foo@type" value="bool" />' +
      '<input type="checkbox" name="foo" value="true" />'
    def_test_view :checkbox_checked, PageForCheckbox,
      '<input type="hidden" name="bar@type" value="bool" />' +
      '<input type="checkbox" name="bar" value="true" checked="checked" />'
    def_test_view :checkbox_content_ignored, PageForCheckbox,
      '<input type="hidden" name="foo@type" value="bool" />' +
      '<input type="checkbox" name="foo" value="true" />'
    def_test_attrs :checkbox, PageForCheckbox, :foo, '<input '

    class PageForRadio < SimplePage
      def initialize
        @foo = 'banana'
      end

      gluon_export_accessor :foo,
        :type => :radio, :list => %w[ apple banana orange ]
    end

    def_test_view :radio, PageForRadio,
      '<input type="radio" name="foo" value="apple" />'
    def_test_view :radio_checked, PageForRadio,
      '<input type="radio" name="foo" value="banana" checked="checked" />'
    def_test_view :radio_content_ignored, PageForRadio,
      '<input type="radio" name="foo" value="apple" />'
    def_test_attrs :radio, PageForRadio, :foo, '<input '

    class PageForSelect < SimplePage
      def initialize
        @fruits = [
          %w[ apple Apple ],
          %w[ banana Banana ],
          %w[ orange Orange ]
        ]
        @foo = 'banana'
        @bar = %w[ apple orange ]
      end

      attr_reader :fruits
      gluon_export_accessor :foo,
        :type => :select, :list => instance_method(:fruits)
      gluon_export_accessor :bar,
        :type => :select, :list => instance_method(:fruits), :multiple => true
    end

    def_test_view :select, PageForSelect,
      '<select name="foo">' +
      '<option value="apple">Apple</option>' +
      '<option value="banana" selected="selected">Banana</option>' +
      '<option value="orange">Orange</option>' +
      '</select>'
    def_test_view :select_content_ignored, PageForSelect,
      '<select name="foo">' +
      '<option value="apple">Apple</option>' +
      '<option value="banana" selected="selected">Banana</option>' +
      '<option value="orange">Orange</option>' +
      '</select>'
    def_test_view :select_multiple, PageForSelect,
      '<input type="hidden" name="bar@type" value="list" />' +
      '<select name="bar" multiple="multiple">' +
      '<option value="apple" selected="selected">Apple</option>' +
      '<option value="banana">Banana</option>' +
      '<option value="orange" selected="selected">Orange</option>' +
      '</select>'
    def_test_attrs :select, PageForSelect, :foo, '<select '

    class PageForTextarea < SimplePage
      def initialize
        @foo = nil
        @bar = "Hello world.\n"
      end

      gluon_export_accessor :foo, :type => :textarea
      gluon_export_accessor :bar, :type => :textarea
    end

    def_test_view :textarea, PageForTextarea,
      '<textarea name="foo"></textarea>'
    def_test_view :textarea_value, PageForTextarea,
      %Q'<textarea name="bar">Hello world.\n</textarea>'
    def_test_view :textarea_content_ignored, PageForTextarea,
      '<textarea name="foo"></textarea>'
    def_test_attrs :textarea, PageForTextarea, :foo, '<textarea '
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
