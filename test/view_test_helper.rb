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
    include Caller

    def view_template(at=1)
      file, line, method = caller_frame(at)
      if (method !~ /^test_/) then
        raise "not a test method of `#{self.class}\#{method}'"
      end
      __send__('view_template_' + method.sub(/^test_/, ''))
    end
    private :view_template

    def view_expected(at=1)
      file, line, method = caller_frame(at)
      if (method !~ /^test_/) then
        raise "not a test method of `#{self.class}\#{method}'"
      end
      __send__('view_expected_' + method.sub(/^test_/, ''))
    end
    private :view_expected

    def view_message(at=1)
      file, line, method = caller_frame(at)
      if (method !~ /^test_/) then
        raise "not a test method of `#{self.class}\#{method}'"
      end
      name = 'view_template_' + method.sub(/^test_/, '')
      "test of `#{self.class}\##{name}'"
    end
    private :view_message

    def self.def_view_test(name, page_type, expected)
      file, line, method = Caller.caller_frame(1)
      module_eval(<<-EOF, "#{__FILE__},test_#{name}(#{line})", __LINE__ + 1)
        def test_#{name}
          build_page(#{page_type})
          assert_equal(view_expected,
                       render_page(view_template),
                       view_message)
        end

        def view_expected_#{name}
          #{expected.dump}
        end
      EOF
    end

    class SimplePage
      include Gluon::Controller
    end

    def_view_test :simple, SimplePage, "Hello world.\n"

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

    def_view_test :value, PageForValue, 'Hello world.'
    def_view_test :value_escape, PageForValue, '&amp;&lt;&gt;&quot; foo'
    def_view_test :value_no_escape, PageForValue, '&<>" foo'
    def_view_test :value_content_ignored, PageForValue, 'Hello world.'

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

    def_view_test :cond_true, PageForCond, 'should be picked up.'
    def_view_test :cond_false, PageForCond, ''

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

    def_view_test :foreach, PageForForeach, '[apple][banana][orange]'
    def_view_test :foreach_empty_list, PageForForeach, ''

    class PageForLink < SimplePage
      def foo
        return '/Foo', :text => 'foo'
      end
      gluon_advice :foo, :type => :link
    end

    def_view_test :link, PageForLink,
      '<a href="/bar.cgi/Foo">foo</a>'
    def_view_test :link_content, PageForLink,
      '<a href="/bar.cgi/Foo">should be picked up.</a>'

    class PageForLinkURI < SimplePage
      def ruby_home
        return 'http://www.ruby-lang.org', :text => 'Ruby'
      end
      gluon_advice :ruby_home, :type => :link_uri
    end

    def_view_test :link_uri, PageForLinkURI,
      '<a href="http://www.ruby-lang.org">Ruby</a>'
    def_view_test :link_uri_content, PageForLinkURI,
      '<a href="http://www.ruby-lang.org">should be picked up.</a>'

    class PageForAction < SimplePage
      def foo
      end
      gluon_export :foo, :type => :action, :text => 'Action'
    end

    def_view_test :action, PageForAction,
      '<a href="/bar.cgi?foo%28%29">Action</a>'
    def_view_test :action_content, PageForAction,
      '<a href="/bar.cgi?foo%28%29">should be picked up.</a>'

    class PageForFrame < SimplePage
      def foo
        '/Foo'
      end
      gluon_advice :foo, :type => :frame
    end

    def_view_test :frame, PageForFrame,
      '<frame src="/bar.cgi/Foo" />'
    def_view_test :frame_content_ignored, PageForFrame,
      '<frame src="/bar.cgi/Foo" />'

    class PageForFrameURI < SimplePage
      def ruby_home
        'http://www.ruby-lang.org'
      end
      gluon_advice :ruby_home, :type => :frame_uri
    end

    def_view_test :frame_uri, PageForFrameURI,
      '<frame src="http://www.ruby-lang.org" />'
    def_view_test :frame_uri_content_ignored, PageForFrameURI,
      '<frame src="http://www.ruby-lang.org" />'

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

    def_view_test :import, PageForImport, '[should be picked up.]'
    def_view_test :import_content, PageForImport, '[should be picked up.]'
    def_view_test :import_content_default, PageForImport, '[should be picked up.]'

    def test_import_content_not_defined
      build_page(PageForImport)
      assert_raise(RuntimeError, view_message) {
        render_page(view_template)
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

    def_view_test :text, PageForText,
      '<input type="text" name="foo" value="" />'
    def_view_test :text_value, PageForText,
      '<input type="text" name="bar" value="should be picked up." />'
    def_view_test :text_content_ignored, PageForText,
      '<input type="text" name="foo" value="" />'

    class PageForPassword < SimplePage
      def initialize
        @foo = nil
        @bar = 'should be picked up.'
      end

      gluon_export_accessor :foo, :type => :password
      gluon_export_accessor :bar, :type => :password
    end

    def_view_test :password, PageForPassword,
      '<input type="password" name="foo" value="" />'
    def_view_test :password_value, PageForPassword,
      '<input type="password" name="bar" value="should be picked up." />'
    def_view_test :password_content_ignored, PageForPassword,
      '<input type="password" name="foo" value="" />'

    class PageForSubmit < SimplePage
      def foo
      end
      gluon_export :foo, :type => :submit

      def bar
      end
      gluon_export :bar, :type => :submit, :value => 'should be picked up.'
    end

    def_view_test :submit, PageForSubmit,
      '<input type="submit" name="foo()" />'
    def_view_test :submit_value, PageForSubmit,
      '<input type="submit" name="bar()" value="should be picked up." />'
    def_view_test :submit_content_ignored, PageForSubmit,
      '<input type="submit" name="foo()" />'

    class PageForHidden < SimplePage
      def initialize
        @foo = nil
        @bar = 'Hello world.'
      end

      gluon_export_accessor :foo, :type => :hidden
      gluon_export_accessor :bar, :type => :hidden
    end

    def_view_test :hidden, PageForHidden,
      '<input type="hidden" name="foo" value="" />'
    def_view_test :hidden_value, PageForHidden,
      '<input type="hidden" name="bar" value="Hello world." />'
    def_view_test :hidden_content_ignored, PageForHidden,
      '<input type="hidden" name="foo" value="" />'

    class PageForCheckbox < SimplePage
      def initialize
        @foo = false
        @bar = true
      end

      gluon_export_accessor :foo, :type => :checkbox
      gluon_export_accessor :bar, :type => :checkbox
    end

    def_view_test :checkbox, PageForCheckbox,
      '<input type="hidden" name="foo@type" value="bool" />' +
      '<input type="checkbox" name="foo" value="true" />'
    def_view_test :checkbox_checked, PageForCheckbox,
      '<input type="hidden" name="bar@type" value="bool" />' +
      '<input type="checkbox" name="bar" value="true" checked="checked" />'
    def_view_test :checkbox_content_ignored, PageForCheckbox,
      '<input type="hidden" name="foo@type" value="bool" />' +
      '<input type="checkbox" name="foo" value="true" />'

    class PageForRadio < SimplePage
      def initialize
        @foo = 'banana'
      end

      gluon_export_accessor :foo,
        :type => :radio, :list => %w[ apple banana orange ]
    end

    def_view_test :radio, PageForRadio,
      '<input type="radio" name="foo" value="apple" />'
    def_view_test :radio_checked, PageForRadio,
      '<input type="radio" name="foo" value="banana" checked="checked" />'
    def_view_test :radio_content_ignored, PageForRadio,
      '<input type="radio" name="foo" value="apple" />'

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

    def_view_test :select, PageForSelect,
      '<select name="foo">' +
      '<option value="apple">Apple</option>' +
      '<option value="banana" selected="selected">Banana</option>' +
      '<option value="orange">Orange</option>' +
      '</select>'
    def_view_test :select_content_ignored, PageForSelect,
      '<select name="foo">' +
      '<option value="apple">Apple</option>' +
      '<option value="banana" selected="selected">Banana</option>' +
      '<option value="orange">Orange</option>' +
      '</select>'
    def_view_test :select_multiple, PageForSelect,
      '<input type="hidden" name="bar@type" value="list" />' +
      '<select name="bar" multiple="multiple">' +
      '<option value="apple" selected="selected">Apple</option>' +
      '<option value="banana">Banana</option>' +
      '<option value="orange" selected="selected">Orange</option>' +
      '</select>'

    class PageForTextarea < SimplePage
      def initialize
        @foo = nil
        @bar = "Hello world.\n"
      end

      gluon_export_accessor :foo, :type => :textarea
      gluon_export_accessor :bar, :type => :textarea
    end

    def_view_test :textarea, PageForTextarea,
      '<textarea name="foo"></textarea>'
    def_view_test :textarea_value, PageForTextarea,
      %Q'<textarea name="bar">Hello world.\n</textarea>'
    def_view_test :textarea_content_ignored, PageForTextarea,
      '<textarea name="foo"></textarea>'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
