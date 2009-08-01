#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'
require 'view_test_helper'

module Gluon::Test
  class ERBViewTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    include ViewTestHelper

    def target_view_module
      Gluon::ERBView
    end

    def view_template_simple
      "Hello world.\n"
    end

    def view_template_value
      '<%= value :foo %>'
    end

    def view_template_value_escape
      '<%= value :bar %>'
    end

    def view_template_value_no_escape
      '<%= value :baz %>'
    end

    def view_template_value_content_ignored
      '<%= value :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_cond_true
      '<% cond :foo? do %>should be picked up.<% end %>'
    end

    def view_template_cond_false
      '<% cond :bar? do %>should be ignored.<% end %>'
    end

    def view_template_foreach
      '<ol><% foreach :foo do %><li><%= value %></li><% end %></ol>'
    end

    def view_template_foreach_empty_list
      '<% foreach :bar do %>should be ignored.<% end %>'
    end

    def view_template_link
      '<%= link :foo %>'
    end

    def view_template_link_content
      '<% link_tag :foo do %>should be picked up.<% end %>'
    end

    def view_template_link_class
      '<%= link :bar %>'
    end

    def view_template_link_embedded_attrs
      '<%= link :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def_test_view :link_embedded_string, SimplePage,
      '<a href="http://www.ruby-lang.org">http://www.ruby-lang.org</a>'

    def view_template_link_embedded_string
      '<%= link "http://www.ruby-lang.org" %>'
    end

    def_test_view :link_embedded_string_content, SimplePage,
      '<a href="http://www.ruby-lang.org">Ruby</a>'

    def view_template_link_embedded_string_content
      '<%= link "http://www.ruby-lang.org", :text => "Ruby" %>'
    end

    def_test_view :link_embedded_class, SimplePage,
      '<a href="/bar.cgi/another_page/foo/123">/bar.cgi/another_page/foo/123</a>'

    def view_template_link_embedded_class
      %Q'<%= link #{AnotherPage}, :path_info => "/foo/123" %>'
    end

    def view_template_action
      '<%= action :foo %>'
    end

    def view_template_action_text
      '<%= action :bar %>'
    end

    def view_template_action_content
      '<% action_tag :bar do %>should be picked up.<% end %>'
    end

    def view_template_action_embedded_attrs
      '<%= action :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def_test_view :action_page, PageForAction,
      '<a href="/bar.cgi/another_page/foo/123?foo%28%29">foo</a>'

    def view_template_action_page
      %Q'<%= action :foo, :page => #{AnotherPage}, :path_info => "/foo/123" %>'
    end

    def view_template_frame
      '<%= frame :foo %>'
    end

    def view_template_frame_content_ignored
      '<%= frame :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_frame_class
      '<%= frame :bar %>'
    end

    def view_template_frame_embedded_attrs
      '<%= frame :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def_test_view :frame_embedded_string, SimplePage,
      '<frame src="http://www.ruby-lang.org" />'

    def view_template_frame_embedded_string
      '<%= frame "http://www.ruby-lang.org" %>'
    end

    def_test_view :frame_embedded_class, SimplePage,
      '<frame src="/bar.cgi/another_page/foo/123" />'

    def view_template_frame_embedded_class
      %Q'<%= frame #{AnotherPage}, :path_info => "/foo/123" %>'
    end

    def view_template_import
      '[<%= import :foo %>]'
    end

    def view_template_import_content
      '<% import_tag :bar do %>should be picked up.<% end %>'
    end

    def view_template_import_content_default
      '<%= import :baz %>'
    end

    def view_template_import_content_not_defined
      '<%= import :bar %>'
    end

    def view_template_text
      '<%= text :foo %>'
    end

    def view_template_text_value
      '<%= text :bar %>'
    end

    def view_template_text_content_ignored
      '<%= text :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_text_embedded_attrs
      '<%= text :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def view_template_password
      '<%= password :foo %>'
    end

    def view_template_password_value
      '<%= password :bar %>'
    end

    def view_template_password_content_ignored
      '<%= password :foo do |out| "should be ignored." end %>'
    end

    def view_template_password_embedded_attrs
      '<%= password :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def view_template_submit
      '<%= submit :foo %>'
    end

    def view_template_submit_value
      '<%= submit :bar %>'
    end

    def view_template_submit_content_ignored
      '<%= submit :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_submit_embedded_attrs
      '<%= submit :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def view_template_hidden
      '<%= hidden :foo %>'
    end

    def view_template_hidden_value
      '<%= hidden :bar %>'
    end

    def view_template_hidden_content_ignored
      '<%= hidden :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_hidden_embedded_attrs
      '<%= hidden :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def view_template_checkbox
      '<%= checkbox :foo %>'
    end

    def view_template_checkbox_checked
      '<%= checkbox :bar %>'
    end

    def view_template_checkbox_content_ignored
      '<%= checkbox :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_checkbox_embedded_attrs
      '<%= checkbox :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def view_template_radio
      '<%= radio :foo, "apple" %>'
    end

    def view_template_radio_checked
      '<%= radio :foo, "banana" %>'
    end

    def view_template_radio_content_ignored
      '<%= radio :foo, "apple" do |out| out << "should be ignored." end %>'
    end

    def view_template_radio_embedded_attrs
      '<%= radio :foo, "apple", "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def view_template_select
      '<%= select :foo %>'
    end

    def view_template_select_content_ignored
      '<%= select :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_select_multiple
      '<%= select :bar, :multiple => true %>'
    end

    def view_template_select_embedded_attrs
      '<%= select :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
    end

    def view_template_textarea
      '<%= textarea :foo %>'
    end

    def view_template_textarea_value
      '<%= textarea :bar %>'
    end

    def view_template_textarea_content_ignored
      '<%= textarea :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_textarea_embedded_attrs
      '<%= textarea :foo, "foo" => "Apple", "bar" => "Banana", "baz" => true %>'
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
        out << "#{self.class}::TEST_ONLY_ONCE[:only_once] += 1"
        out << " end %>"
        out << "<% "
        out << "#{self.class}::TEST_ONLY_ONCE[:not_only_once] += 1"
        out << " %>"
      }

      10.times do |i|
        n = i + 1
        assert_equal('', @controller.page_render(@po))
        assert_equal(1, TEST_ONLY_ONCE[:only_once], "count: #{n}")
        assert_equal(n, TEST_ONLY_ONCE[:not_only_once], "count :#{n}")
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
