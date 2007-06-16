#!/usr/local/bin/ruby

require 'fileutils'
require 'gluon/dispatcher'
require 'gluon/po'
require 'gluon/renderer'
require 'gluon/rs'
require 'rack'
require 'test/unit'

module Gluon::Test
  class PresentationObjectTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    class AnotherPage
    end

    def setup
      @view_dir = 'view'
      FileUtils.mkdir_p(@view_dir)
      @renderer = Gluon::ViewRenderer.new(@view_dir)

      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @env['SCRIPT_NAME'] = '/bar.cgi'
      @env['PATH_INFO'] = ''
      @req = Rack::Request.new(@env)
      @res = Rack::Response.new
      @dispatcher = Gluon::Dispatcher.new([ [ '/another_page', AnotherPage ] ])
      @c = Gluon::RequestResponseContext.new(@req, @res, @dispatcher)
    end

    def teardown
      FileUtils.rm_rf(@view_dir)
    end

    def build_page(page_type)
      @page = page_type.new
      @po = Gluon::PresentationObject.new(@page, @c, @renderer)
      @context = Gluon::ERBContext.new(@po, @c)
    end
    private :build_page

    def render_page(eruby_script)
      Gluon::ViewRenderer.render(@context, eruby_script, '(erb)')
    end
    private :render_page

    class PageForImplicitViewName
    end

    def test_view_name_implicit
      build_page(PageForImplicitViewName)
      assert_equal('Gluon/Test/PresentationObjectTest/PageForImplicitViewName.rhtml', @po.view_name)
    end

    class PageForExplicitViewName
      def view_name
        'foo.rhtml'
      end
    end

    def test_view_name_explicit
      build_page(PageForExplicitViewName)
      assert_equal('foo.rhtml', @po.view_name)
    end

    class PageForValue
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
                   render_page('<% cond :foo, :not => true do %>HALO<% end %>'))
      assert_equal('HALO',
                   render_page('<% cond :bar, :not => true do %>HALO<% end %>'))

      assert_equal('',
                   render_page('<% not_cond :foo do %>HALO<% end %>'))
      assert_equal('HALO',
                   render_page('<% not_cond :bar do %>HALO<% end %>'))
    end

    class PageForForeach
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
      def foo_path
        '/Foo'
      end

      def foo_text
        'foo'
      end

      def page_with_query
        return AnotherPage, :query => { 'foo' => 'bar' }
      end
    end

    class NotMountedPage
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
      assert_equal('<a href="/bar.cgi/Foo?foo=bar">foo</a>',
                   render_page('<%= link "/Foo", :query => { "foo" => "bar" }, :text => "foo" %>'))

      assert_equal('<a href="/bar.cgi/Foo">/bar.cgi/Foo</a>',
                   render_page('<%= link :foo_path %>'))
      assert_equal('<a href="/bar.cgi/Foo">foo</a>',
                   render_page('<%= link :foo_path, :text => :foo_text %>'))
      assert_equal('<a id="foo" href="/bar.cgi/Foo">foo</a>',
                   render_page('<%= link :foo_path, :text => :foo_text, :id => "foo" %>'))
      assert_equal('<a href="/bar.cgi/Foo" target="_blank">foo</a>',
                   render_page('<%= link :foo_path, :text => :foo_text, :target => "_blank" %>'))
      assert_equal('<a href="/bar.cgi/Foo?foo=bar">foo</a>',
                   render_page('<%= link :foo_path, :query => { "foo" => "bar" }, :text => "foo" %>'))

      assert_equal('<a href="/bar.cgi/another_page">/bar.cgi/another_page</a>',
                   render_page("<%= link #{AnotherPage} %>"))
      assert_equal('<a href="/bar.cgi/another_page">another page</a>',
                   render_page("<%= link #{AnotherPage}, :text => 'another page' %>"))
      assert_equal('<a id="another_page" href="/bar.cgi/another_page">another page</a>',
                   render_page("<%= link #{AnotherPage}, :text => 'another page', :id => 'another_page' %>"))
      assert_equal('<a href="/bar.cgi/another_page" target="_blank">another page</a>',
                   render_page("<%= link #{AnotherPage}, :text => 'another page', :target => '_blank' %>"))
      assert_equal('<a href="/bar.cgi/another_page?foo=bar">another page</a>',
                   render_page("<%= link #{AnotherPage}, :query => { 'foo' => 'bar' }, :text => 'another page' %>"))

      assert_equal('<a href="/bar.cgi/another_page?foo=bar">query</a>',
                   render_page('<%= link :page_with_query, :text => "query" %>'))
      assert_equal('<a href="/bar.cgi/another_page?foo=baz">query</a>',
                   render_page('<%= link :page_with_query, :query => { "foo" => "baz" }, :text => "query" %>'))
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
      def foo
      end
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
      def another_page
        AnotherPage
      end
    end

    class AnotherPage
      def view_name
        'AnotherPage.rhtml'
      end

      def hello
        'Hello world.'
      end
    end

    def test_import
      File.open(File.join(@view_dir, 'AnotherPage.rhtml'), 'w') {|out|
        out.binmode
        out << '<%= value :hello %>'
      }
      build_page(PageForImport)

      assert_equal('[Hello world.]', render_page("[<%= import #{AnotherPage} %>]"))
      assert_equal('[Hello world.]', render_page('[<%= import :another_page %>]'))
    end

    def test_query
      params = {}
      def params.each
        alist = self.to_a
        alist.sort!{|a, b| a[0] <=> b[0] }
        alist.each do |name, value|
          yield(name, value)
        end
        self
      end

      params['foo'] = 'bar'
      params['baz'] = nil
      assert_equal('baz&foo=bar', Gluon::PresentationObject.query(params))

      params.clear
      params['foo'] = '&'
      params['bar'] = '='
      params['baz'] = '%'
      assert_equal('bar=%3D&baz=%25&foo=%26', Gluon::PresentationObject.query(params))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
