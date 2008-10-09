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

    def caller_frame(at=caller[1])
      if (/^(.+?):(\d+)(?::in `(.*)')?/ =~ at) then
        file = $1
        line = $2.to_i
        method = $3
        return file, line, method
      end

      nil
    end
    private :caller_frame

    def view_template
      file, line, method = caller_frame
      if (method !~ /^test_/) then
        raise "not a test method of `#{self.class}\#{method}'"
      end
      __send__('view_template_' + method.sub(/^test_/, ''))
    end
    private :view_template

    def view_expected
      file, line, method = caller_frame
      if (method !~ /^test_/) then
        raise "not a test method of `#{self.class}\#{method}'"
      end
      __send__('view_expected_' + method.sub(/^test_/, ''))
    end
    private :view_expected

    def view_message
      file, line, method = caller_frame
      if (method !~ /^test_/) then
        raise "not a test method of `#{self.class}\#{method}'"
      end
      name = 'view_template_' + method.sub(/^test_/, '')
      "test of `#{self.class}\##{name}'"
    end
    private :view_message

    def self.def_view_test(name, page_type, expected)
      module_eval(<<-EOF, "#{__FILE__},test_#{name}()", __LINE__ + 1)
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

    class PageForLink
      include Gluon::Controller

      def foo
        return '/Foo', :text => 'foo'
      end
      gluon_advice :foo, :type => :link
    end

    def_view_test :link, PageForLink,
      '<a href="/bar.cgi/Foo">foo</a>'
    def_view_test :link_content, PageForLink,
      '<a href="/bar.cgi/Foo">Hello world.</a>'

    class PageForLinkURI
      include Gluon::Controller

      def ruby_home
        return 'http://www.ruby-lang.org', :text => 'Ruby'
      end
      gluon_advice :ruby_home, :type => :link_uri
    end

    def_view_test :link_uri, PageForLinkURI,
      '<a href="http://www.ruby-lang.org">Ruby</a>'
    def_view_test :link_uri_content, PageForLinkURI,
      '<a href="http://www.ruby-lang.org">ruby</a>'

    class PageForAction
      include Gluon::Controller

      def foo
      end
      gluon_export :foo, :type => :action, :text => 'Action'
    end

    def_view_test :action, PageForAction,
      '<a href="/bar.cgi?foo%28%29">Action</a>'
    def_view_test :action_content, PageForAction,
      '<a href="/bar.cgi?foo%28%29">Hello world.</a>'

    class PageForFrame
      include Gluon::Controller

      def foo
        '/Foo'
      end
      gluon_advice :foo, :type => :frame
    end

    def_view_test :frame, PageForFrame,
      '<frame src="/bar.cgi/Foo" />'
    def_view_test :frame_content_ignored, PageForFrame,
      '<frame src="/bar.cgi/Foo" />'

    class PageForFrameURI
      include Gluon::Controller

      def ruby_home
        'http://www.ruby-lang.org'
      end
      gluon_advice :ruby_home, :type => :frame_uri
    end

    def_view_test :frame_uri, PageForFrameURI,
      '<frame src="http://www.ruby-lang.org" />'
    def_view_test :frame_uri_content_ignored, PageForFrameURI,
      '<frame src="http://www.ruby-lang.org" />'

    class PageForImport
      class Foo
        include Gluon::Controller

        def page_import         # checked by Gluon::Action
        end

        def page_render(po)
          'Hello world.'
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
          '[' + po.content{|out| out << 'Hello world.' } + ']'
        end
      end

      include Gluon::Controller

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

    def_view_test :import, PageForImport, '[Hello world.]'
    def_view_test :import_content, PageForImport, '[Hello world.]'
    def_view_test :import_content_default, PageForImport, '[Hello world.]'

    def test_import_content_not_defined
      build_page(PageForImport)
      assert_raise(RuntimeError, view_message) {
        render_page(view_template)
      }
    end

    class PageForText
      include Gluon::Controller
      gluon_export_accessor :foo, :type => :text
    end

    def_view_test :text, PageForText,
      '<input type="text" name="foo" value="" />'
    def_view_test :text_content_ignored, PageForText,
      '<input type="text" name="foo" value="" />'

    class PageForPassword
      include Gluon::Controller
      gluon_export_accessor :foo, :type => :password
    end

    def_view_test :password, PageForPassword,
      '<input type="password" name="foo" value="" />'
    def_view_test :password_content_ignored, PageForPassword,
      '<input type="password" name="foo" value="" />'

    class PageForSubmit
      include Gluon::Controller

      def foo
      end
      gluon_export :foo, :type => :submit
    end

    def_view_test :submit, PageForSubmit,
      '<input type="submit" name="foo()" />'
    def_view_test :submit_content_ignored, PageForSubmit,
      '<input type="submit" name="foo()" />'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
