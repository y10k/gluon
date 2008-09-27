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
      include Gluon::Controller
      include Gluon::ERBView
    end

    VIEW_DIR = 'view'

    def setup
      @view_dir = VIEW_DIR
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
      @controller.page_render(@po)
    end
    private :render_page

    def assert_optional_id(page_type, expr, method)
      build_page(page_type)
      assert_match(/ id="foo"/,
                   render_page(%Q'<%= #{expr}, :id => "foo" %>'))
      assert_match(/ id="foo"/,
                   render_page(%Q'<%= #{expr}, :id => "foo", :attrs => { "id" => "bar" } %>'))
      assert_no_match(/ id="bar"/,
                      render_page(%Q'<%= #{expr}, :id => "foo", :attrs => { "id" => "bar" } %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_id) { 'foo' }
      }
      build_page(anon_page_type)
      assert_match(/ id="foo"/,
                   render_page(%Q'<%= #{expr}, :id => :optional_id %>'))

      if (method) then
        anon_page_type = Class.new(page_type) {
          gluon_advice method, :id => 'foo'
        }
        build_page(anon_page_type)
        assert_match(/ id="foo"/,
                     render_page(%Q'<%= #{expr} %>'))
        assert_match(/ id="bar"/,
                     render_page(%Q'<%= #{expr}, :id => "bar" %>'))
        assert_no_match(/ id="foo"/,
                        render_page(%Q'<%= #{expr}, :id => "bar" %>'))

        anon_page_type = Class.new(page_type) {
          gluon_advice method, :id => proc{ 'foo' }
        }
        build_page(anon_page_type)
        assert_match(/ id="foo"/,
                     render_page(%Q'<%= #{expr} %>'))

        anon_page_type = Class.new(page_type) {
          define_method(:optional_id) { 'foo' }
          gluon_advice method, :id => instance_method(:optional_id)
        }
        build_page(anon_page_type)
        assert_match(/ id="foo"/,
                     render_page(%Q'<%= #{expr} %>'))
      end
    end
    private :assert_optional_id

    def assert_optional_class(page_type, expr, method)
      build_page(page_type)
      assert_match(/ class="foo"/,
                   render_page(%Q'<%= #{expr}, :class => "foo" %>'))
      assert_match(/ class="foo"/,
                   render_page(%Q'<%= #{expr}, :class => "foo", :attrs => { "class" => "bar" } %>'))
      assert_no_match(/ class="bar"/,
                      render_page(%Q'<%= #{expr}, :class => "foo", :attrs => { "class" => "bar" } %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_class) { 'foo' }
      }
      build_page(anon_page_type)
      assert_match(/ class="foo"/,
                   render_page(%Q'<%= #{expr}, :class => :optional_class %>'))

      if (method) then
        anon_page_type = Class.new(page_type) {
          gluon_advice method, :class => 'foo'
        }
        build_page(anon_page_type)
        assert_match(/ class="foo"/,
                     render_page(%Q'<%= #{expr} %>'))
        assert_match(/ class="bar"/,
                     render_page(%Q'<%= #{expr}, :class => "bar" %>'))
        assert_no_match(/ class="foo"/,
                        render_page(%Q'<%= #{expr}, :class => "bar" %>'))

        anon_page_type = Class.new(page_type) {
          gluon_advice method, :class => proc{ 'foo' }
        }
        build_page(anon_page_type)
        assert_match(/ class="foo"/,
                     render_page(%Q'<%= #{expr} %>'))

        anon_page_type = Class.new(page_type) {
          define_method(:optional_class) { 'foo' }
          gluon_advice method, :class => instance_method(:optional_class)
        }
        build_page(anon_page_type)
        assert_match(/ class="foo"/,
                     render_page(%Q'<%= #{expr} %>'))
      end
    end
    private :assert_optional_class

    def assert_optional_attrs(page_type, expr, reserved_attrs)
      build_page(page_type)

      assert_match(/ foo="Apple" bar="Banana"/,
                   render_page(%Q'<%= #{expr}, :attrs => { "foo" => "Apple", "bar" => "Banana" } %>'))

      for name in reserved_attrs
        assert_match(/^[a-z]+$/, name)
        assert_no_match(/ #{Regexp.quote(name)}="not expected."/,
                        render_page(%Q'<%= #{expr}, :attrs => { #{name.dump} => "not expected." } %>'))

        name = name.upcase
        assert_no_match(/ #{Regexp.quote(name)}="not expected."/,
                        render_page(%Q'<%= #{expr}, :attrs => { #{name.dump} => "not expected." } %>'))
      end

      assert_raise(TypeError) {
        render_page(%Q'<%= #{expr}, :attrs => { :foo => "not expected." } %>')
      }
    end
    private :assert_optional_attrs

    def assert_optional_disabled(page_type, expr)
      build_page(page_type)
      assert_match(/ disabled="disabled"/,
                   render_page(%Q'<%= #{expr}, :disabled => true %>'))
      assert_no_match(/ disabled="disabled"/,
                   render_page(%Q'<%= #{expr}, :disabled => false %>'))
      assert_no_match(/ disabled="disabled"/,
                   render_page(%Q'<%= #{expr} %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_disabled?) { true }
      }
      build_page(anon_page_type)
      assert_match(/ disabled="disabled"/,
                   render_page(%Q'<%= #{expr}, :disabled => :optional_disabled? %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_disabled?) { false }
      }
      build_page(anon_page_type)
      assert_no_match(/ disabled="disabled"/,
                      render_page(%Q'<%= #{expr}, :disabled => :optional_disabled? %>'))
    end
    private :assert_optional_disabled

    def assert_optional_readonly(page_type, expr)
      build_page(PageForText)
      assert_match(/ readonly="readonly"/,
                   render_page(%Q'<%= #{expr}, :readonly => true %>'))
      assert_no_match(/ readonly="readonly"/,
                   render_page(%Q'<%= #{expr}, :readonly => false %>'))
      assert_no_match(/ readonly="readonly"/,
                   render_page(%Q'<%= #{expr} %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_readonly?) { true }
      }
      build_page(anon_page_type)
      assert_match(/ readonly="readonly"/,
                   render_page(%Q'<%= #{expr}, :readonly => :optional_readonly? %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_readonly?) { false }
      }
      build_page(anon_page_type)
      assert_no_match(/ readonly="readonly"/,
                      render_page(%Q'<%= #{expr}, :readonly => :optional_readonly? %>'))
    end
    private :assert_optional_readonly

    def assert_optional_size(page_type, expr)
      build_page(page_type)
      assert_match(/ size="123"/,
                   render_page(%Q'<%= #{expr}, :size => 123 %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_size) { 123 }
      }
      build_page(anon_page_type)
      assert_match(/ size="123"/,
                   render_page(%Q'<%= #{expr}, :size => :optional_size %>'))
    end
    private :assert_optional_size

    def assert_optional_maxlength(page_type, expr)
      build_page(page_type)
      assert_match(/ maxlength="123"/,
                   render_page(%Q'<%= #{expr}, :maxlength => 123 %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_maxlength) { 123 }
      }
      build_page(anon_page_type)
      assert_match(/ maxlength="123"/,
                   render_page(%Q'<%= #{expr}, :maxlength => :optional_maxlength %>'))
    end
    private :assert_optional_size

    def assert_optional_rows(page_type, expr)
      build_page(page_type)
      assert_match(/ rows="123"/,
                   render_page(%Q'<%= #{expr}, :rows => 123 %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_rows) { 123 }
      }
      build_page(anon_page_type)
      assert_match(/ rows="123"/,
                   render_page(%Q'<%= #{expr}, :rows => :optional_rows %>'))
    end
    private :assert_optional_size

    def assert_optional_cols(page_type, expr)
      build_page(page_type)
      assert_match(/ cols="123"/,
                   render_page(%Q'<%= #{expr}, :cols => 123 %>'))

      anon_page_type = Class.new(page_type) {
        define_method(:optional_cols) { 123 }
      }
      build_page(anon_page_type)
      assert_match(/ cols="123"/,
                   render_page(%Q'<%= #{expr}, :cols => :optional_cols %>'))
    end
    private :assert_optional_size

    class PageForValue
      include Gluon::Controller
      include Gluon::ERBView

      def foo
        'Hello world.'
      end

      def bar
        '&<>" foo'
      end

      def yes
        true
      end

      def no
        false
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

      assert_equal('Hello world.',
                   render_page('<%= value :foo, :escape => :yes %>'))
      assert_equal('&amp;&lt;&gt;&quot; foo',
                   render_page('<%= value :bar, :escape => :yes %>'))

      assert_equal('Hello world.',
                   render_page('<%= value :foo, :escape => :no %>'))
      assert_equal('&<>" foo',
                   render_page('<%= value :bar, :escape => :no %>'))
    end

    def test_value_with_advice
      anon_page_type = Class.new(PageForValue) {
        gluon_advice :foo, :escape => true
        gluon_advice :bar, :escape => true
      }
      build_page(anon_page_type)

      assert_equal('Hello world.',
                   render_page('<%= value :foo %>'))
      assert_equal('&amp;&lt;&gt;&quot; foo',
                   render_page('<%= value :bar %>'))

      anon_page_type = Class.new(PageForValue) {
        gluon_advice :foo, :escape => false
        gluon_advice :bar, :escape => false
      }
      build_page(anon_page_type)

      assert_equal('Hello world.',
                   render_page('<%= value :foo %>'))
      assert_equal('&<>" foo',
                   render_page('<%= value :bar %>'))
    end

    class PageForCond
      include Gluon::Controller
      include Gluon::ERBView

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
      include Gluon::Controller
      include Gluon::ERBView

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
      include Gluon::Controller
      include Gluon::ERBView

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

    def test_link_optional_id
      assert_optional_id(PageForLink, 'link :foo_path', :foo_path)
    end

    def test_link_optional_class
      assert_optional_class(PageForLink, 'link :foo_path', :foo_path)
    end

    def test_link_optional_attrs
      assert_optional_attrs(PageForLink, 'link :foo_path',
                            Gluon::PresentationObject::MKLINK_RESERVED_ATTRS.keys)
    end

    def test_link_error
      build_page(PageForLink)
      assert_raise(TypeError) {
        render_page('<%= link 123 %>')
      }
      assert_raise(TypeError) {
        render_page('<%= link "foo", :text => 123 %>')
      }
      assert_raise(RuntimeError) {
        render_page("<%= link #{NotMountedPage} %>")
      }
    end

    class PageForLinkURI
      include Gluon::Controller
      include Gluon::ERBView

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

    def test_link_uri_optional_id
      assert_optional_id(PageForLinkURI,
                         'link_uri :ruby_home_uri',
                         :ruby_home_uri)
    end

    def test_link_uri_optional_class
      assert_optional_class(PageForLinkURI,
                            'link_uri :ruby_home_uri',
                            :ruby_home_uri)
    end

    def test_link_uri_optional_attrs
      assert_optional_attrs(PageForLinkURI,
                            'link_uri :ruby_home_uri',
                            Gluon::PresentationObject::MKLINK_RESERVED_ATTRS.keys)
    end

    def test_link_uri_error
      build_page(PageForLinkURI)
      assert_raise(TypeError) {
        render_page('<%= link_uri 123 %>')
      }
      assert_raise(TypeError) {
        render_page('<%= link_uri "foo", :text => 123 %>')
      }
    end

    class PageForAction
      include Gluon::Controller
      include Gluon::ERBView

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

    def test_action_with_advice
      anon_page_type = Class.new(PageForAction) {
        gluon_advice :foo, :query => { 'bar' => 'HALO' }, :text => 'Hello'
      }
      build_page(anon_page_type)
      rendered_view = render_page('<%= action :foo %>')
      assert_match(/<a href="[^"]*bar=HALO[^"]*"/, rendered_view, 'query advice')
      assert_match(%r'^<a.*>Hello</a>$', rendered_view, 'text advice')
    end

    def test_action_optional_id
      assert_optional_id(PageForAction, 'action :foo', :foo)
    end

    def test_action_optional_class
      assert_optional_class(PageForAction, 'action :foo', :foo)
    end

    def test_action_optional_attrs
      assert_optional_attrs(PageForAction, 'action :foo',
                            Gluon::PresentationObject::MKLINK_RESERVED_ATTRS.keys)
    end

    class PageForFrame
      include Gluon::Controller
      include Gluon::ERBView

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

    def test_frame_optional_id
      assert_optional_id(PageForFrame, 'frame :foo', :foo)
    end

    def test_frame_optional_class
      assert_optional_class(PageForFrame, 'frame :foo', :foo)
    end

    def test_frame_optional_attrs
      assert_optional_attrs(PageForFrame, 'frame :foo',
                            Gluon::PresentationObject::MKFRAME_RESERVED_ATTRS.keys)
    end

    def test_frame_error
      build_page(PageForFrame)
      assert_raise(TypeError) {
        render_page('<%= frame 123 %>')
      }
    end

    class PageForFrameURI
      include Gluon::Controller
      include Gluon::ERBView

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

    def test_frame_uri_optional_id
      assert_optional_id(PageForFrameURI, 'frame_uri :ruby_home', :ruby_home)
    end

    def test_frame_uri_optional_class
      assert_optional_class(PageForFrameURI, 'frame_uri :ruby_home', :ruby_home)
    end

    def test_frame_uri_optional_attrs
      assert_optional_attrs(PageForFrameURI,
                            'frame_uri :ruby_home',
                            Gluon::PresentationObject::MKFRAME_RESERVED_ATTRS.keys)
    end

    def test_frame_uri_error
      build_page(PageForFrameURI)
      assert_raise(TypeError) {
        render_page('<%= frame_uri 123 %>')
      }
    end

    class PageForImport
      include Gluon::Controller
      include Gluon::ERBView

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
      include Gluon::Controller
      include Gluon::ERBView

      def initialize(message='Hello world.')
        @message = message
      end

      attr_reader :message

      def page_import           # checked by Gluon::Action
      end

      def page_render(po)
        @c.view_render(Gluon::ERBView, File.join(VIEW_DIR, 'Subpage.rhtml'), po)
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
      include Gluon::Controller
      include Gluon::ERBView
      gluon_export_accessor :foo
    end

    def test_text
      build_page(PageForText)

      assert_equal('<input type="text" name="foo" value="" />', render_page('<%= text :foo %>'))

      @controller.foo = 'Hello world.'
      assert_equal('<input type="text" name="foo" value="Hello world." />', render_page('<%= text :foo %>'))
    end

    def test_text_optional_id
      assert_optional_id(PageForText, 'text :foo', :foo)
    end

    def test_text_optional_class
      assert_optional_class(PageForText, 'text :foo', :foo)
    end

    def test_text_optional_attrs
      assert_optional_attrs(PageForText, 'text :foo',
                            Gluon::PresentationObject::MKINPUT_RESERVED_ATTRS.keys)
    end

    def test_text_optional_disabled
      assert_optional_disabled(PageForText, 'text :foo')
    end

    def test_text_optional_readonly
      assert_optional_readonly(PageForText, 'text :foo')
    end

    def test_text_size
      assert_optional_size(PageForText, 'text :foo')
    end

    def test_text_maxlength
      assert_optional_maxlength(PageForText, 'text :foo')
    end

    class PageForPassword
      include Gluon::Controller
      include Gluon::ERBView
      gluon_export_accessor :foo
    end

    def test_password
      build_page(PageForPassword)

      assert_equal('<input type="password" name="foo" value="" />', render_page('<%= password :foo %>'))

      @controller.foo = 'Hello world.'
      assert_equal('<input type="password" name="foo" value="Hello world." />', render_page('<%= password :foo %>'))
    end

    def test_password_optional_id
      assert_optional_id(PageForPassword, 'password :foo', :foo)
    end

    def test_password_optional_class
      assert_optional_class(PageForPassword, 'password :foo', :foo)
    end

    def test_password_optional_attrs
      assert_optional_attrs(PageForPassword, 'password :foo',
                            Gluon::PresentationObject::MKINPUT_RESERVED_ATTRS.keys)
    end

    def test_password_optional_disabled
      assert_optional_disabled(PageForPassword, 'password :foo')
    end

    def test_password_optional_readonly
      assert_optional_readonly(PageForPassword, 'password :foo')
    end

    def test_password_size
      assert_optional_size(PageForPassword, 'password :foo')
    end

    def test_password_maxlength
      assert_optional_maxlength(PageForPassword, 'password :foo')
    end

    class PageForSubmit
      include Gluon::Controller
      include Gluon::ERBView

      def foo
      end
      gluon_export :foo
    end

    def test_submit
      build_page(PageForSubmit)

      assert_equal('<input type="submit" name="foo()" />', render_page('<%= submit :foo %>'))
      assert_equal('<input type="submit" name="foo()" value="Push!" />',
                   render_page('<%= submit :foo, :value => "Push!" %>'))
    end

    def test_submit_optional_id
      assert_optional_id(PageForSubmit, 'submit :foo', :foo)
    end

    def test_submit_optional_class
      assert_optional_class(PageForSubmit, 'submit :foo', :foo)
    end

    def test_submit_optional_attrs
      assert_optional_attrs(PageForSubmit, 'submit :foo',
                            Gluon::PresentationObject::MKINPUT_RESERVED_ATTRS.keys)
    end

    def test_submit_optional_disabled
      assert_optional_disabled(PageForSubmit, 'submit :foo')
    end

    def test_submit_optional_readonly
      assert_optional_readonly(PageForSubmit, 'submit :foo')
    end

    class PageForHidden
      include Gluon::Controller
      include Gluon::ERBView
      gluon_export_accessor :foo
    end

    def test_hidden
      build_page(PageForHidden)

      assert_equal('<input type="hidden" name="foo" value="" />', render_page('<%= hidden :foo %>'))

      @controller.foo = 'Hello world.'
      assert_equal('<input type="hidden" name="foo" value="Hello world." />', render_page('<%= hidden :foo %>'))
    end

    def test_hidden_optional_id
      assert_optional_id(PageForHidden, 'hidden :foo', :foo)
    end

    def test_hidden_optional_class
      assert_optional_class(PageForHidden, 'hidden :foo', :foo)
    end

    def test_hidden_optional_attrs
      assert_optional_attrs(PageForHidden, 'hidden :foo',
                            Gluon::PresentationObject::MKINPUT_RESERVED_ATTRS.keys)
    end

    def test_hidden_optional_disabled
      assert_optional_disabled(PageForHidden, 'hidden :foo')
    end

    def test_hidden_optional_readonly
      assert_optional_readonly(PageForHidden, 'hidden :foo')
    end

    class PageForCheckbox
      include Gluon::Controller
      include Gluon::ERBView
      gluon_export_accessor :foo
    end

    def test_checkbox
      build_page(PageForCheckbox)

      @controller.foo = false
      assert_equal('<input type="hidden" name="foo@type" value="bool" /><input type="checkbox" name="foo" value="true" />',
                   render_page('<%= checkbox :foo %>'))

      @controller.foo = true
      assert_equal('<input type="hidden" name="foo@type" value="bool" /><input type="checkbox" name="foo" value="true" checked="checked" />',
                   render_page('<%= checkbox :foo %>'))
    end

    def test_checkbox_optional_id
      assert_optional_id(PageForCheckbox, 'checkbox :foo', :foo)
    end

    def test_checkbox_optional_class
      assert_optional_class(PageForCheckbox, 'checkbox :foo', :foo)
    end

    def test_checkbox_optional_attrs
      assert_optional_attrs(PageForCheckbox, 'checkbox :foo',
                            Gluon::PresentationObject::MKINPUT_RESERVED_ATTRS.keys)
    end

    def test_checkbox_optional_disabled
      assert_optional_disabled(PageForCheckbox, 'checkbox :foo')
    end

    def test_checkbox_optional_readonly
      assert_optional_readonly(PageForCheckbox, 'checkbox :foo')
    end

    class PageForRadio
      include Gluon::Controller
      include Gluon::ERBView
      gluon_export_accessor :foo
    end

    def test_radio
      build_page(PageForRadio)

      @controller.foo = 'Apple'
      assert_equal('<input type="radio" name="foo" value="Banana" />',
                   render_page('<%= radio :foo, "Banana" %>'))

      @controller.foo = 'Orange'
      assert_equal('<input type="radio" name="foo" value="Orange" checked="checked" />',
                   render_page('<%= radio :foo, "Orange" %>'))
    end

    def test_radio_with_advice
      anon_page_type = Class.new(PageForRadio) {
        gluon_advice :foo, :list => %w[ Apple Banana Orange ]
      }
      build_page(anon_page_type)

      @controller.foo = 'Apple'
      assert_equal('<input type="radio" name="foo" value="Banana" />',
                   render_page('<%= radio :foo, "Banana" %>'))

      @controller.foo = 'Orange'
      assert_equal('<input type="radio" name="foo" value="Orange" checked="checked" />',
                   render_page('<%= radio :foo, "Orange" %>'))

      assert_raise(ArgumentError) {
        render_page('<%= radio :foo, "Melon" %>')
      }
    end

    def test_radio_optional_id
      assert_optional_id(PageForRadio, 'radio :foo, "Banana"', :foo)
    end

    def test_radio_optional_class
      assert_optional_class(PageForRadio, 'radio :foo, "Banana"', :foo)
    end

    def test_radio_optional_attrs
      assert_optional_attrs(PageForRadio, 'radio :foo, "Banana"',
                            Gluon::PresentationObject::MKINPUT_RESERVED_ATTRS.keys)
    end

    def test_radio_optional_disabled
      assert_optional_disabled(PageForRadio, 'radio :foo, "Banana"')
    end

    def test_radio_optional_readonly
      assert_optional_readonly(PageForRadio, 'radio :foo, "Banana"')
    end

    class PageForSelect
      include Gluon::Controller
      include Gluon::ERBView
      gluon_export_accessor :foo
      attr_reader :fruits

      def initialize
        @fruits = [
          %w[ apple Apple ],
          %w[ banana Banana ],
          %w[ orange Orange ]
        ]
      end
    end

    def test_select
      build_page(PageForSelect)

      @controller.foo = 'banana'
      assert_equal('<select name="foo">' +
                   '<option value="apple">Apple</option>' +
                   '<option value="banana" selected="selected">Banana</option>' +
                   '<option value="orange">Orange</option>' +
                   '</select>',
                   render_page('<%= select :foo, :list => :fruits %>'))
    end

    def test_select_with_advice
      anon_page_type = Class.new(PageForSelect) {
        gluon_advice :foo, :list => instance_method(:fruits)
      }
      build_page(anon_page_type)

      @controller.foo = 'banana'
      assert_equal('<select name="foo">' +
                   '<option value="apple">Apple</option>' +
                   '<option value="banana" selected="selected">Banana</option>' +
                   '<option value="orange">Orange</option>' +
                   '</select>',
                   render_page('<%= select :foo %>'))
    end

    def test_select_optional_id
      assert_optional_id(PageForSelect, 'select :foo, :list => :fruits', :foo)
    end

    def test_select_optional_class
      assert_optional_class(PageForSelect, 'select :foo, :list => :fruits', :foo)
    end

    def test_select_optional_attrs
      assert_optional_attrs(PageForSelect, 'select :foo, :list => :fruits',
                            Gluon::PresentationObject::SELECT_RESERVED_ATTRS.keys)
    end

    def test_select_optional_disabled
      assert_optional_disabled(PageForSelect, 'select :foo, :list => :fruits')
    end

    def test_multiple_select
      build_page(PageForSelect)

      @controller.foo = %w[ apple orange ]
      assert_equal('<input type="hidden" name="foo@type" value="list" />' +
                   '<select name="foo" multiple="multiple">' +
                   '<option value="apple" selected="selected">Apple</option>' +
                   '<option value="banana">Banana</option>' +
                   '<option value="orange" selected="selected">Orange</option>' +
                   '</select>',
                   render_page('<%= select :foo, :list => :fruits, :multiple => true %>'))
    end

    class PageForTextarea
      include Gluon::Controller
      include Gluon::ERBView
      gluon_export_accessor :foo
    end

    def test_textarea
      build_page(PageForTextarea)

      assert_equal('<textarea name="foo"></textarea>',
                   render_page('<%= textarea :foo %>'))

      @controller.foo = "Hello world.\n"
      assert_equal("<textarea name=\"foo\">Hello world.\n</textarea>",
                   render_page('<%= textarea :foo %>'))
    end

    def test_textarea_optional_id
      assert_optional_id(PageForTextarea, 'textarea :foo', :foo)
    end

    def test_textarea_optional_class
      assert_optional_class(PageForTextarea, 'textarea :foo', :foo)
    end

    def test_textarea_optional_attrs
      assert_optional_attrs(PageForTextarea, 'textarea :foo',
                            Gluon::PresentationObject::TEXTAREA_RESERVED_ATTRS.keys)
    end

    def test_textarea_optional_disabled
      assert_optional_disabled(PageForTextarea, 'textarea :foo')
    end

    def test_textarea_optional_readonly
      assert_optional_readonly(PageForTextarea, 'textarea :foo')
    end

    def test_textarea_optional_rows
      assert_optional_rows(PageForTextarea, 'textarea :foo')
    end

    def test_textarea_optional_cols
      assert_optional_cols(PageForTextarea, 'textarea :foo')
    end

    class PageForForeachAction
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def initialize
          @calls = 0
        end

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
      include Gluon::Controller
      include Gluon::ERBView

      def initialize
        @subpage = SubpageAction.new
      end

      gluon_reader :subpage
    end

    class SubpageAction
      include Gluon::Controller
      include Gluon::ERBView

      def initialize
        @calls = 0
        @c = nil
      end

      attr_reader :calls

      def page_import           # checked by Gluon::Action
        @c.validation = true
      end

      def foo
        @calls += 1
      end
      gluon_export :foo

      def page_render(po)
        @c.view_render(Gluon::ERBView, File.join(VIEW_DIR, 'SubpageAction.rhtml'), po)
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

    class PageForValueInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
          'Apple'
        end
      end

      def initialize
        @list = [ Item.new ]
      end

      attr_reader :list

      def bar
        'Banana'
      end
    end

    def test_value_in_loop_inside_scope
      build_page(PageForValueInLoop)
      assert_equal('Apple',
                   render_page('<% foreach :list do %>' +
                               '<%= value :foo %>' +
                               '<% end %>'))
    end

    def test_value_in_loop_outside_scope
      build_page(PageForValueInLoop)
      assert_equal('Banana',
                   render_page('<% foreach :list do %>' +
                               '<%= value :bar %>' +
                               '<% end %>'))
    end

    class PageForCondInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo?
          true
        end
      end

      def initialize
        @list = [ Item.new ]
        @bar = 'Banana'
      end

      attr_reader :list

      def bar?
        true
      end
    end

    def test_cond_in_loop_inside_scope
      build_page(PageForCondInLoop)
      assert_equal('True',
                   render_page('<% foreach :list do %>' +
                               '<% cond :foo? do %>True<% end %>' +
                               '<% end %>'))
    end

    def test_cond_in_loop_outside_scope
      build_page(PageForCondInLoop)
      assert_equal('True',
                   render_page('<% foreach :list do %>' +
                               '<% cond :bar? do %>True<% end %>' +
                               '<% end %>'))
    end

    class PageForForeachInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
          %w[ x y z ]
        end
      end

      def initialize
        @list = [ Item.new ]
      end

      attr_reader :list

      def bar
        %w[ xx yy zz ]
      end
    end

    def test_foreach_in_loop_inside_scope
      build_page(PageForForeachInLoop)
      assert_equal('xyz',
                   render_page('<% foreach :list do %>' +
                               '<% foreach :foo do %><%= value %><% end %>' +
                               '<% end %>'))
    end

    def test_foreach_in_loop_outside_scope
      build_page(PageForForeachInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<% foreach :bar do %><%= value %><% end %>' +
                    '<% end %>')
      }
    end

    class PageForLinkInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
          '/Foo'
        end
      end

      def initialize
        @list = [ Item.new ]
      end

      attr_reader :list

      def bar
        '/Bar'
      end
    end

    def test_link_in_loop_inside_scope
      build_page(PageForLinkInLoop)
      assert_equal('<a href="/bar.cgi/Foo">/bar.cgi/Foo</a>',
                   render_page('<% foreach :list do %>' +
                               '<%= link :foo %>' +
                               '<% end %>'))
    end

    def test_link_in_loop_outside_scope
      build_page(PageForLinkInLoop)
      assert_equal('<a href="/bar.cgi/Bar">/bar.cgi/Bar</a>',
                   render_page('<% foreach :list do %>' +
                               '<%= link :bar %>' +
                               '<% end %>'))
    end

    class PageForLinkURIInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
          'http://foo'
        end
      end

      def initialize
        @list = [ Item.new ]
      end

      attr_reader :list

      def bar
        'http://bar'
      end
    end

    def test_link_uri_in_loop_inside_scope
      build_page(PageForLinkURIInLoop)
      assert_equal('<a href="http://foo">http://foo</a>',
                   render_page('<% foreach :list do %>' +
                               '<%= link_uri :foo %>' +
                               '<% end %>'))
    end

    def test_link_uri_in_loop_outside_scope
      build_page(PageForLinkURIInLoop)
      assert_equal('<a href="http://bar">http://bar</a>',
                   render_page('<% foreach :list do %>' +
                               '<%= link_uri :bar %>' +
                               '<% end %>'))
    end

    class PageForActionInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
        end
        gluon_export :foo
      end

      def initialize
        @list = [ Item.new ]
      end

      gluon_export_reader :list

      def bar
      end
      gluon_export :bar
    end

    def test_action_in_loop_insde_scope
      build_page(PageForActionInLoop)
      assert_equal('<a href="/bar.cgi?list%5B0%5D.foo%28%29">foo</a>',
                   render_page('<% foreach :list do %>' +
                               '<%= action :foo %>' +
                               '<% end %>'))
    end

    def test_action_in_loop_outside_scope
      build_page(PageForActionInLoop)
      assert_equal('<a href="/bar.cgi?bar%28%29">bar</a>',
                   render_page('<% foreach :list do %>' +
                               '<%= action :bar %>' +
                               '<% end %>'))
    end

    class PageForFrameInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
          '/Foo'
        end
      end

      def initialize
        @list = [ Item.new ]
      end

      attr_reader :list

      def bar
        '/Bar'
      end
    end

    def test_frame_in_loop_inside_scope
      build_page(PageForFrameInLoop)
      assert_equal('<frame src="/bar.cgi/Foo" />',
                   render_page('<% foreach :list do %>' +
                               '<%= frame :foo %>' +
                               '<% end %>'))
    end

    def test_frame_in_loop_outside_scope
      build_page(PageForFrameInLoop)
      assert_equal('<frame src="/bar.cgi/Bar" />',
                   render_page('<% foreach :list do %>' +
                               '<%= frame :bar %>' +
                               '<% end %>'))
    end

    class PageForFrameURIInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
          'http://foo'
        end
      end

      def initialize
        @list = [ Item.new ]
      end

      attr_reader :list

      def bar
        'http://bar'
      end
    end

    def test_frame_uri_in_loop_inside_scope
      build_page(PageForFrameURIInLoop)
      assert_equal('<frame src="http://foo" />',
                   render_page('<% foreach :list do %>' +
                               '<%= frame_uri :foo %>' +
                               '<% end %>'))
    end

    def test_frame_uri_in_loop_outside_scope
      build_page(PageForFrameURIInLoop)
      assert_equal('<frame src="http://bar" />',
                   render_page('<% foreach :list do %>' +
                               '<%= frame_uri :bar %>' +
                               '<% end %>'))
    end

    class PageForImportInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Subpage
        include Gluon::Controller

        def initialize(text)
          @text = text
        end

        attr_reader :text

        def page_import         # checked by Gluon::Action
        end

        def page_render(po)
          @c.view_render(Gluon::ERBView, File.join(VIEW_DIR, 'Subpage.rhtml'), po)
        end
      end

      class Item
        def initialize
          @foo = Subpage.new('foo')
        end

        attr_reader :foo
      end

      def initialize
        @list = [ Item.new ]
        @bar = Subpage.new('bar')
      end

      attr_reader :list
      attr_reader :bar
    end

    def test_import_in_loop_inside_scope
      File.open(File.join(VIEW_DIR, 'Subpage.rhtml'), 'w') {|out|
        out << '<%= value :text %>'
      }
      build_page(PageForImportInLoop)
      assert_equal('foo',
                   render_page('<% foreach :list do %>' +
                               '<%= import :foo %>' +
                               '<% end %>'))
    end

    def test_import_in_loop_outside_scope
      File.open(File.join(VIEW_DIR, 'Subpage.rhtml'), 'w') {|out|
        out << '<%= value :text %>'
      }
      build_page(PageForImportInLoop)
      assert_equal('bar',
                   render_page('<% foreach :list do %>' +
                               '<%= import :bar %>' +
                               '<% end %>'))
    end

    class PageForTextInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        gluon_export_accessor :foo
      end

      def initialize
        @list = [ Item.new ]
      end

      gluon_export_reader :list
      gluon_export_accessor :bar
    end

    def test_text_in_loop_inside_scope
      build_page(PageForTextInLoop)
      assert_equal('<input type="text" name="list[0].foo" value="" />',
                   render_page('<% foreach :list do %>' +
                               '<%= text :foo %>' +
                               '<% end %>'))
    end

    def test_text_in_loop_outside_scope
      build_page(PageForTextInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= text :bar %>' +
                    '<% end %>')
      }
    end

    class PageForPasswordInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        gluon_export_accessor :foo
      end

      def initialize
        @list = [ Item.new ]
      end

      gluon_export_reader :list
      gluon_export_accessor :bar
    end

    def test_password_in_loop_inside_scope
      build_page(PageForPasswordInLoop)
      assert_equal('<input type="password" name="list[0].foo" value="" />',
                   render_page('<% foreach :list do %>' +
                               '<%= password :foo %>' +
                               '<% end %>'))
    end

    def test_password_in_loop_outside_scope
      build_page(PageForPasswordInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= password :bar %>' +
                    '<% end %>')
      }
    end

    class PageForSubmitInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def foo
        end
        gluon_export :foo
      end

      def initialize
        @list = [ Item.new ]
      end

      gluon_export_reader :list

      def bar
      end
      gluon_export :bar
    end

    def test_submit_in_loop_inside_scope
      build_page(PageForSubmitInLoop)
      assert_equal('<input type="submit" name="list[0].foo()" />',
                   render_page('<% foreach :list do %>' +
                               '<%= submit :foo %>' +
                               '<% end %>'))
    end

    def test_submit_in_loop_inside_scope
      build_page(PageForSubmitInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= submit :bar %>' +
                    '<% end %>')
      }
    end

    class PageForHiddenInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        gluon_export_accessor :foo
      end

      def initialize
        @list = [ Item.new ]
      end

      gluon_export_reader :list
      gluon_export_accessor :bar
    end

    def test_hidden_in_loop_inside_scope
      build_page(PageForHiddenInLoop)
      assert_equal('<input type="hidden" name="list[0].foo" value="" />',
                   render_page('<% foreach :list do %>' +
                               '<%= hidden :foo %>' +
                               '<% end %>'))
    end

    def test_hidden_in_loop_outside_scope
      build_page(PageForHiddenInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= hidden :bar %>' +
                    '<% end %>')
      }
    end

    class PageForCheckboxInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def initialize
          @foo = true
        end

        gluon_export_accessor :foo
      end

      def initialize
        @list = [ Item.new ]
        @bar = false
      end

      gluon_export_reader :list
      gluon_export_accessor :bar
    end

    def test_checkbox_in_loop_inside_scope
      build_page(PageForCheckboxInLoop)
      assert_equal('<input type="hidden" name="list[0].foo@type" value="bool" />' +
                   '<input type="checkbox" name="list[0].foo" value="true" checked="checked" />',
                   render_page('<% foreach :list do %>' +
                               '<%= checkbox :foo %>' +
                               '<% end %>'))
    end

    def test_checkbox_in_loop_outside_scope
      build_page(PageForCheckboxInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= checkbox :bar %>' +
                    '<% end %>')
      }
    end

    class PageForRadioInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def initialize
          @foo = 'Apple'
        end

        gluon_export_accessor :foo
      end

      def initialize
        @list = [ Item.new ]
        @bar = 'Banana'
      end

      gluon_export_reader :list
      gluon_export_accessor :bar
    end

    def test_radio_in_loop_inside_scope
      build_page(PageForRadioInLoop)
      assert_equal('<input type="radio" name="list[0].foo" value="Apple" checked="checked" />',
                   render_page('<% foreach :list do %>' +
                               '<%= radio :foo, "Apple" %>' +
                               '<% end %>'))
    end

    def test_radio_in_loop_outside_scope
      build_page(PageForRadioInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= radio :bar, "Apple" %>' +
                    '<% end %>')
      }
    end

    class PageForSelectInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        def initialize
          @foo = 'Apple'
        end

        gluon_export_accessor :foo, :list => %w[ Apple Banana Orange ]
      end

      def initialize
        @list = [ Item.new ]
        @bar = 'Bob'
      end

      gluon_export_reader :list
      gluon_export_accessor :bar, :list => %w[ Alice Bob Kate ]
    end

    def test_select_in_loop_inside_scope
      build_page(PageForSelectInLoop)
      assert_equal('<select name="list[0].foo">' +
                   '<option value="Apple" selected="selected">Apple</option>' +
                   '<option value="Banana">Banana</option>' +
                   '<option value="Orange">Orange</option>' +
                   '</select>',
                   render_page('<% foreach :list do %>' +
                               '<%= select :foo %>' +
                               '<% end %>'))
    end

    def test_select_in_loop_outside_scope
      build_page(PageForSelectInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= select :bar %>' +
                    '<% end %>')
      }
    end

    class PageForTextareaInLoop
      include Gluon::Controller
      include Gluon::ERBView

      class Item
        gluon_export_accessor :foo
      end

      def initialize
        @list = [ Item.new ]
      end

      gluon_export_reader :list
      gluon_export_accessor :bar
    end

    def test_textarea_in_loop_inside_scope
      build_page(PageForTextareaInLoop)
      assert_equal('<textarea name="list[0].foo"></textarea>',
                   render_page('<% foreach :list do %>' +
                               '<%= textarea :foo %>' +
                               '<% end %>'))
    end

    def test_textarea_in_loop_outside_scope
      build_page(PageForTextareaInLoop)
      assert_raise(NoMethodError) {
        render_page('<% foreach :list do %>' +
                    '<%= textarea :bar %>' +
                    '<% end %>')
      }
    end

    TEST_ONLY_ONCE = {
      :only_once => 0,
      :not_only_once => 0
    }

    class PageForOnlyOnce
      include Gluon::Controller
      include Gluon::ERBView
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
