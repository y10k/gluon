#!/usr/local/bin/ruby

require 'fileutils'
require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class PresentationObjectTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    class AnotherPage
      attr_writer :c
    end

    def setup
      @view_dir = 'view'
      FileUtils.rm_rf(@view_dir) # for debug
      FileUtils.mkdir_p(@view_dir)
      @renderer = Gluon::ViewRenderer.new(@view_dir)

      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @mock = Gluon::Mock.new(:url_map => { AnotherPage => '/another_page' },
                              :view_dir => @view_dir)
    end

    def teardown
      FileUtils.rm_rf(@view_dir) unless $DEBUG
    end

    def build_page(page_type)
      @c = @mock.new_request(@env)
      @params, @funcs = Gluon::Action.parse(@c.req.params)
      @controller = page_type.new
      @controller.c = @c
      @action = Gluon::Action.new(@controller, @c, @params, @funcs)
      @po = Gluon::PresentationObject.new(@controller, @c, @action)
    end
    private :build_page

    def render_page(eruby_script, filename=nil)
      unless (filename) then
        filename = @c.default_template(@controller) + Gluon::ERBView::SUFFIX
      end
      FileUtils.mkdir_p(File.dirname(filename))
      File.open("#{filename}.tmp", 'w') {|out|
        out << eruby_script
      }
      File.rename("#{filename}.tmp", filename) # to change i-node

      unless (@controller.respond_to? :page_render) then
        @controller.extend(Gluon::ERBView)
      end
      @controller.page_render(@po)
    end
    private :render_page

    class PageForValue
      attr_writer :c

      def foo
        'Hello world.'
      end

      def bar
        '&<>" foo'
      end
    end

    def test_value
      build_page(PageForValue)

      assert_equal('Hello world.',
                   render_page('<%= value :foo %>'))
      assert_equal('&amp;&lt;&gt;&quot; foo',
                   render_page('<%= value :bar %>'))

      assert_equal('Hello world.',
                   render_page('<%= value :foo, :escape => true %>'))
      assert_equal('&amp;&lt;&gt;&quot; foo',
                   render_page('<%= value :bar, :escape => true %>'))

      assert_equal('Hello world.',
                   render_page('<%= value :foo, :escape => false %>'))
      assert_equal('&<>" foo',
                   render_page('<%= value :bar, :escape => false %>'))
    end

    class PageForCond
      attr_writer :c

      def foo
        true
      end

      def bar
        false
      end
    end

    def test_cond
      build_page(PageForCond)

      assert_equal('HALO',
                   render_page('<% cond :foo do %>HALO<% end %>'))
      assert_equal('',
                   render_page('<% cond :bar do %>HALO<% end %>'))

      assert_equal('',
                   render_page('<% cond :foo, :negate => true do %>HALO<% end %>'))
      assert_equal('HALO',
                   render_page('<% cond :bar, :negate => true do %>HALO<% end %>'))

      assert_equal('',
                   render_page('<% cond neg(:foo) do %>HALO<% end %>'))
      assert_equal('HALO',
                   render_page('<% cond neg(:bar) do %>HALO<% end %>'))

      assert_equal('',
                   render_page('<% cond NOT(:foo) do %>HALO<% end %>'))
      assert_equal('HALO',
                   render_page('<% cond NOT(:bar) do %>HALO<% end %>'))
    end

    class PageForForeach
      attr_writer :c

      def foo
        %w[ apple banana orange ]
      end

      def bar
        []
      end
    end

    def test_foreach
      build_page(PageForForeach)

      assert_equal('[apple][banana][orange]',
                   render_page('<% foreach :foo do %>[<%= value %>]<% end %>'))
      assert_equal('',
                   render_page('<% foreach :bar do %>[<%= value %>]<% end %>'))

      assert_equal('[1.apple][2.banana][3.orange]',
                   render_page('<% foreach :foo do |i| %>[<%= i.succ %>.<%= value %>]<% end %>'))
      assert_equal('',
                   render_page('<% foreach :bar do |i| %>[<%= i.succ %>.<%= value %>]<% end %>'))
    end

    class PageForLink
      attr_writer :c

      def foo_path
        '/Foo'
      end

      def foo_text
        'foo'
      end

      def page_with_query
        return AnotherPage, :query => { 'foo' => 'bar' }
      end

      def page_with_fragment
        return AnotherPage, :fragment => 'foo'
      end

      def page_with_query_and_fragment
        return AnotherPage, :query => { 'foo' => 'bar' }, :fragment => 'foo'
      end
    end

    class NotMountedPage
      attr_writer :c
    end

    def test_link
      build_page(PageForLink)

      assert_equal('<a href="/bar.cgi/Foo">/bar.cgi/Foo</a>',
                   render_page('<%= link "/Foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo">foo</a>',
                   render_page('<%= link "/Foo", :text => "foo" %>'))
      assert_equal('<a id="foo" href="/bar.cgi/Foo">foo</a>',
                   render_page('<%= link "/Foo", :text => "foo", :id => "foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo" target="_blank">foo</a>',
                   render_page('<%= link "/Foo", :text => "foo", :target => "_blank" %>'))
      assert_equal('<a href="/bar.cgi/Foo#foo">foo</a>',
                   render_page('<%= link "/Foo", :text => "foo", :fragment => "foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo?foo=bar">foo</a>',
                   render_page('<%= link "/Foo", :query => { "foo" => "bar" }, :text => "foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo?foo=bar#foo">foo</a>',
                   render_page('<%= link "/Foo", :query => { "foo" => "bar" }, :fragment => "foo", :text => "foo" %>'))

      assert_equal('<a href="/bar.cgi/Foo">/bar.cgi/Foo</a>',
                   render_page('<%= link :foo_path %>'))
      assert_equal('<a href="/bar.cgi/Foo">foo</a>',
                   render_page('<%= link :foo_path, :text => :foo_text %>'))
      assert_equal('<a id="foo" href="/bar.cgi/Foo">foo</a>',
                   render_page('<%= link :foo_path, :text => :foo_text, :id => "foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo" target="_blank">foo</a>',
                   render_page('<%= link :foo_path, :text => :foo_text, :target => "_blank" %>'))
      assert_equal('<a href="/bar.cgi/Foo#foo">foo</a>',
                   render_page('<%= link :foo_path, :text => :foo_text, :fragment => "foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo?foo=bar">foo</a>',
                   render_page('<%= link :foo_path, :query => { "foo" => "bar" }, :text => "foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo?foo=bar#foo">foo</a>',
                   render_page('<%= link :foo_path, :query => { "foo" => "bar" }, :fragment => "foo", :text => "foo"%>'))

      assert_equal('<a href="/bar.cgi/another_page">/bar.cgi/another_page</a>',
                   render_page("<%= link #{AnotherPage} %>"))
      assert_equal('<a href="/bar.cgi/another_page">another page</a>',
                   render_page("<%= link #{AnotherPage}, :text => 'another page' %>"))
      assert_equal('<a id="another_page" href="/bar.cgi/another_page">another page</a>',
                   render_page("<%= link #{AnotherPage}, :text => 'another page', :id => 'another_page' %>"))
      assert_equal('<a href="/bar.cgi/another_page" target="_blank">another page</a>',
                   render_page("<%= link #{AnotherPage}, :text => 'another page', :target => '_blank' %>"))
      assert_equal('<a href="/bar.cgi/another_page#foo">another page</a>',
                   render_page("<%= link #{AnotherPage}, :text => 'another page', :fragment => 'foo' %>"))
      assert_equal('<a href="/bar.cgi/another_page?foo=bar">another page</a>',
                   render_page("<%= link #{AnotherPage}, :query => { 'foo' => 'bar' }, :text => 'another page' %>"))
      assert_equal('<a href="/bar.cgi/another_page?foo=bar#foo">another page</a>',
                   render_page("<%= link #{AnotherPage}, :query => { 'foo' => 'bar' }, :fragment => 'foo', :text => 'another page' %>"))

      assert_equal('<a href="/bar.cgi/another_page?foo=bar">query</a>',
                   render_page('<%= link :page_with_query, :text => "query" %>'))
      assert_equal('<a href="/bar.cgi/another_page?foo=baz">query</a>',
                   render_page('<%= link :page_with_query, :query => { "foo" => "baz" }, :text => "query" %>'))
      assert_equal('<a href="/bar.cgi/another_page#foo">fragment</a>',
                   render_page('<%= link :page_with_fragment, :text => "fragment" %>'))
      assert_equal('<a href="/bar.cgi/another_page?foo=bar#foo">query and fragment</a>',
                   render_page('<%= link :page_with_query_and_fragment, :text => "query and fragment" %>'))
    end

    def test_link_error
      build_page(PageForLink)
      assert_raise(RuntimeError) {
        render_page('<%= link 123 %>')
      }
      assert_raise(RuntimeError) {
        render_page('<%= link "foo", :text => 123 %>')
      }
      assert_raise(RuntimeError) {
        render_page("<%= link #{NotMountedPage} %>")
      }
    end

    class PageForLinkURI
      attr_writer :c

      def ruby_home_uri
        'http://www.ruby-lang.org'
      end

      def ruby_home_text
        'Ruby'
      end

      def uri_with_query
        return 'http://www.ruby-lang.org', :query => { 'lang' => 'ja' }
      end
    end

    def test_link_uri
      build_page(PageForLinkURI)

      assert_equal('<a href="http://www.ruby-lang.org">http://www.ruby-lang.org</a>',
                   render_page('<%= link_uri "http://www.ruby-lang.org" %>'))
      assert_equal('<a href="http://www.ruby-lang.org">Ruby</a>',
                   render_page('<%= link_uri "http://www.ruby-lang.org", :text => "Ruby" %>'))
      assert_equal('<a id="ruby" href="http://www.ruby-lang.org">Ruby</a>',
                   render_page('<%= link_uri "http://www.ruby-lang.org", :text => "Ruby", :id => "ruby" %>'))
      assert_equal('<a href="http://www.ruby-lang.org" target="_blank">Ruby</a>',
                   render_page('<%= link_uri "http://www.ruby-lang.org", :text => "Ruby", :target => "_blank" %>'))
      assert_equal('<a href="http://www.ruby-lang.org?lang=ja">Ruby</a>',
                   render_page('<%= link_uri "http://www.ruby-lang.org", :query => { "lang" => "ja" }, :text => "Ruby" %>'))

      assert_equal('<a href="http://www.ruby-lang.org">http://www.ruby-lang.org</a>',
                   render_page('<%= link_uri :ruby_home_uri %>'))
      assert_equal('<a href="http://www.ruby-lang.org">Ruby</a>',
                   render_page('<%= link_uri :ruby_home_uri, :text => :ruby_home_text %>'))
      assert_equal('<a id="ruby" href="http://www.ruby-lang.org">Ruby</a>',
                   render_page('<%= link_uri :ruby_home_uri, :text => :ruby_home_text, :id => "ruby" %>'))
      assert_equal('<a href="http://www.ruby-lang.org" target="_blank">Ruby</a>',
                   render_page('<%= link_uri :ruby_home_uri, :text => :ruby_home_text, :target => "_blank" %>'))
      assert_equal('<a href="http://www.ruby-lang.org?lang=ja">Ruby</a>',
                   render_page('<%= link_uri :ruby_home_uri, :query => { "lang" => "ja" }, :text => :ruby_home_text %>'))

      assert_equal('<a href="http://www.ruby-lang.org?lang=ja">Ruby</a>',
                   render_page('<%= link_uri :uri_with_query, :text => "Ruby" %>'))
      assert_equal('<a href="http://www.ruby-lang.org?lang=en">Ruby</a>',
                   render_page('<%= link_uri :uri_with_query, :query => { "lang" => "en" }, :text => "Ruby" %>'))
    end

    def test_link_uri_error
      build_page(PageForLinkURI)
      assert_raise(RuntimeError) {
        render_page('<%= link_uri 123 %>')
      }
      assert_raise(RuntimeError) {
        render_page('<%= link_uri "foo", :text => 123 %>')
      }
    end

    class PageForAction
      attr_writer :c

      def foo
      end
      gluon_export :foo
    end

    def test_action
      build_page(PageForAction)
      assert_equal('<a href="/bar.cgi?foo%28%29">foo</a>',
                   render_page('<%= action :foo %>'))
      assert_equal('<a href="/bar.cgi?foo%28%29">action</a>',
                   render_page('<%= action :foo, :text => "action" %>'))
      assert_equal('<a id="foo" href="/bar.cgi?foo%28%29">action</a>',
                   render_page('<%= action :foo, :text => "action", :id => "foo" %>'))
      assert_equal('<a href="/bar.cgi?foo%28%29" target="_blank">action</a>',
                   render_page('<%= action :foo, :text => "action", :target => "_blank" %>'))
      assert_equal('<a href="/bar.cgi/another_page?foo%28%29">action</a>',
                   render_page("<%= action :foo, :text => 'action', :page => #{AnotherPage} %>"))
    end

    class PageForFrame
      attr_writer :c

      def foo
        '/Foo'
      end

      def page_with_query
        return AnotherPage, :query => { 'foo' => 'bar' }
      end
    end

    def test_frame
      build_page(PageForFrame)

      assert_equal('<frame src="/bar.cgi/Foo" />',
                   render_page('<%= frame "/Foo" %>'))
      assert_equal('<frame id="foo" src="/bar.cgi/Foo" />',
                   render_page('<%= frame "/Foo", :id => "foo" %>'))
      assert_equal('<frame src="/bar.cgi/Foo" name="foo" />',
                   render_page('<%= frame "/Foo", :name => "foo" %>'))
      assert_equal('<frame src="/bar.cgi/Foo?foo=bar" />',
                   render_page('<%= frame "/Foo", :query => { "foo" => "bar" } %>'))

      assert_equal('<frame src="/bar.cgi/Foo" />',
                   render_page('<%= frame :foo %>'))
      assert_equal('<frame id="foo" src="/bar.cgi/Foo" />',
                   render_page('<%= frame :foo, :id => "foo" %>'))
      assert_equal('<frame src="/bar.cgi/Foo" name="foo" />',
                   render_page('<%= frame :foo, :name => "foo" %>'))
      assert_equal('<frame src="/bar.cgi/Foo?foo=bar" />',
                   render_page('<%= frame :foo, :query => { "foo" => "bar" } %>'))

      assert_equal('<frame src="/bar.cgi/another_page" />',
                   render_page("<%= frame #{AnotherPage} %>"))
      assert_equal('<frame id="foo" src="/bar.cgi/another_page" />',
                   render_page("<%= frame #{AnotherPage}, :id => 'foo' %>"))
      assert_equal('<frame src="/bar.cgi/another_page" name="foo" />',
                   render_page("<%= frame #{AnotherPage}, :name => 'foo' %>"))
      assert_equal('<frame src="/bar.cgi/another_page?foo=bar" />',
                   render_page("<%= frame #{AnotherPage}, :query => { 'foo' => 'bar' } %>"))

      assert_equal('<frame src="/bar.cgi/another_page?foo=bar" />',
                   render_page("<%= frame :page_with_query %>"))
      assert_equal('<frame src="/bar.cgi/another_page?foo=baz" />',
                   render_page("<%= frame :page_with_query, :query => { 'foo' => 'baz' } %>"))
    end

    def test_frame_error
      build_page(PageForFrame)
      assert_raise(RuntimeError) {
        render_page('<%= frame 123 %>')
      }
    end

    class PageForFrameURI
      attr_writer :c

      def ruby_home
        'http://www.ruby-lang.org'
      end

      def uri_with_query
        return 'http://www.ruby-lang.org', :query => { 'lang' => 'ja' }
      end
    end

    def test_frame_uri
      build_page(PageForFrameURI)

      assert_equal('<frame src="http://www.ruby-lang.org" />',
                   render_page('<%= frame_uri "http://www.ruby-lang.org" %>'))
      assert_equal('<frame id="ruby" src="http://www.ruby-lang.org" />',
                   render_page('<%= frame_uri "http://www.ruby-lang.org", :id => "ruby" %>'))
      assert_equal('<frame src="http://www.ruby-lang.org" name="ruby" />',
                   render_page('<%= frame_uri "http://www.ruby-lang.org", :name => "ruby" %>'))
      assert_equal('<frame src="http://www.ruby-lang.org?lang=ja" />',
                   render_page('<%= frame_uri "http://www.ruby-lang.org", :query => { "lang" => "ja" } %>'))

      assert_equal('<frame src="http://www.ruby-lang.org" />',
                   render_page('<%= frame_uri :ruby_home %>'))
      assert_equal('<frame id="ruby" src="http://www.ruby-lang.org" />',
                   render_page('<%= frame_uri :ruby_home, :id => "ruby" %>'))
      assert_equal('<frame src="http://www.ruby-lang.org" name="ruby" />',
                   render_page('<%= frame_uri :ruby_home, :name => "ruby" %>'))
      assert_equal('<frame src="http://www.ruby-lang.org?lang=ja" />',
                   render_page('<%= frame_uri :ruby_home, :query => { "lang" => "ja" } %>'))

      assert_equal('<frame src="http://www.ruby-lang.org?lang=ja" />',
                   render_page('<%= frame_uri :uri_with_query %>'))
      assert_equal('<frame src="http://www.ruby-lang.org?lang=en" />',
                   render_page('<%= frame_uri :uri_with_query, :query => { "lang" => "en" } %>'))
    end

    def test_frame_uri_error
      build_page(PageForFrameURI)
      assert_raise(RuntimeError) {
        render_page('<%= frame_uri 123 %>')
      }
    end

    class PageForImport
      attr_writer :c

      def another_page_class
        Subpage
      end

      def another_page_instance
        Subpage.new
      end

      def another_page_foo
        Subpage.new('foo')
      end
    end

    class Subpage
      attr_writer :c

      def initialize(message='Hello world.')
        @message = message
      end

      attr_reader :message

      def page_import           # checked by Gluon::Action
      end

      def page_render(po)
        @c.view_render(Gluon::ERBView, 'view/Subpage.rhtml', po)
      end
    end

    def test_import
      File.open(File.join(@view_dir, 'Subpage.rhtml'), 'w') {|out|
        out << '<%= value :message %>'
      }
      build_page(PageForImport)

      assert_equal('[Hello world.]', render_page('[<%= import :another_page_class %>]'))
      assert_equal('[Hello world.]', render_page('[<%= import :another_page_instance %>]'))
      assert_equal('[foo]', render_page('[<%= import :another_page_foo %>]'))
      assert_equal('[Hello world.]', render_page("[<%= import #{Subpage} %>]"))
      assert_equal('[Hello world.]', render_page("[<%= import #{Subpage}.new %>]"))
      assert_equal('[foo]', render_page("[<%= import #{Subpage}.new('foo') %>]"))
    end

    class PageForText
      attr_writer :c
      gluon_accessor :foo
    end

    def test_text
      build_page(PageForText)

      assert_equal('<input type="text" name="foo" value="" />', render_page('<%= text :foo %>'))

      @controller.foo = 'Hello world.'
      assert_equal('<input type="text" name="foo" value="Hello world." />', render_page('<%= text :foo %>'))
    end

    class PageForPassword
      attr_writer :c
      gluon_accessor :foo
    end

    def test_password
      build_page(PageForPassword)

      assert_equal('<input type="password" name="foo" value="" />', render_page('<%= password :foo %>'))

      @controller.foo = 'Hello world.'
      assert_equal('<input type="password" name="foo" value="Hello world." />', render_page('<%= password :foo %>'))
    end

    class PageForSubmit
      attr_writer :c

      def foo_action
      end
      gluon_export :foo_action
    end

    def test_submit
      build_page(PageForSubmit)

      assert_equal('<input type="submit" name="foo()" />', render_page('<%= submit :foo %>'))
      assert_equal('<input type="submit" name="foo()" value="Push!" />',
                   render_page('<%= submit :foo, :value => "Push!" %>'))
    end

    class PageForHidden
      attr_writer :c
      gluon_accessor :foo
    end

    def test_hidden
      build_page(PageForHidden)

      assert_equal('<input type="hidden" name="foo" value="" />', render_page('<%= hidden :foo %>'))

      @controller.foo = 'Hello world.'
      assert_equal('<input type="hidden" name="foo" value="Hello world." />', render_page('<%= hidden :foo %>'))
    end

    class PageForForeachAction
      attr_writer :c

      class Item
        def initialize
          @calls = 0
        end

        attr_writer :c
        attr_reader :calls

        def foo
          @calls += 1
        end
        gluon_export :foo
      end

      def initialize
        @list = [ Item.new, Item.new, Item.new ]
      end

      gluon_reader :list
    end

    def test_foreach_action
      @env['QUERY_STRING'] = Gluon::PresentationObject.query('list[1].foo()' => nil)
      build_page(PageForForeachAction)

      assert_equal('010', render_page('<% foreach :list do %><%= value :calls %><% end %>'))
    end

    class PageForImportAction
      def initialize
        @subpage = SubpageAction.new
      end

      attr_writer :c
      gluon_reader :subpage
    end

    class SubpageAction
      def initialize
        @calls = 0
        @c = nil
      end

      attr_reader :calls
      attr_writer :c

      def page_import           # checked by Gluon::Action
        @c.validation = true
      end

      def foo
        @calls += 1
      end
      gluon_export :foo

      def page_render(po)
        @c.view_render(Gluon::ERBView, 'view/SubpageAction.rhtml', po)
      end
    end

    def test_import_action
      @env['QUERY_STRING'] = Gluon::PresentationObject.query('subpage.foo()' => nil)
      File.open(File.join(@view_dir, 'SubpageAction.rhtml'), 'w') {|out|
        out << '<%= value :calls %>'
      }
      build_page(PageForImportAction)

      assert_equal('[1]', render_page('[<%= import :subpage %>]'))
    end

    def test_import_action_no_call
      File.open(File.join(@view_dir, 'SubpageAction.rhtml'), 'w') {|out|
        out << '<%= value :calls %>'
      }
      build_page(PageForImportAction)

      assert_equal('[0]', render_page('[<%= import :subpage %>]'))
    end

    TEST_ONLY_ONCE = {
      :only_once => 0,
      :not_only_once => 0
    }

    class PageForOnlyOnce
      include Gluon::ERBView
      attr_writer :c
    end

    def test_only_once
      build_page(PageForOnlyOnce)

      filename = @c.default_template(@controller) + Gluon::ERBView::SUFFIX
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') {|out|
        out << "<% only_once do "
        out << "#{PresentationObjectTest}::TEST_ONLY_ONCE[:only_once] += 1"
        out << " end %>"
        out << "<% "
        out << "#{PresentationObjectTest}::TEST_ONLY_ONCE[:not_only_once] += 1"
        out << " %>"
      }

      10.times do |i|
        n = i + 1
        assert_equal('', @controller.page_render(@po))
        assert_equal(1, TEST_ONLY_ONCE[:only_once])
        assert_equal(n, TEST_ONLY_ONCE[:not_only_once], "#{n}th")
      end
    end
  end

  class PresentationObjectQueryTest < Test::Unit::TestCase
    def setup
      @params = {}
      def @params.each
        alist = self.to_a
        alist.sort!{|a, b| a[0] <=> b[0] }
        alist.each do |name, value|
          yield(name, value)
        end
        self
      end
    end

    def test_query_simple_value
      @params['foo'] = 'bar'
      @params['baz'] = nil
      assert_equal('baz&foo=bar', Gluon::PresentationObject.query(@params))
    end

    def test_query_special_characters
      @params['foo'] = '&'
      @params['bar'] = '='
      @params['baz'] = '%'
      assert_equal('bar=%3D&baz=%25&foo=%26', Gluon::PresentationObject.query(@params))
    end

    def test_query_list
      @params['foo'] = %w[ apple banana orange ]
      assert_equal('foo=apple&foo=banana&foo=orange', Gluon::PresentationObject.query(@params))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
