#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'
require 'view_test_helper'

module Gluon::Test
  class ERBViewTest < Test::Unit::TestCase
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
      '<% foreach :foo do %>[<%= value %>]<% end %>'
    end

    def view_template_foreach_empty_list
      '<% foreach :bar do %>should be ignored.<% end %>'
    end

    def view_template_link
      '<%= link :foo %>'
    end

    def view_template_link_content
      '<%= link :foo do |out| out << "should be picked up." end %>'
    end

    def view_template_link_uri
      '<%= link_uri :ruby_home %>'
    end

    def view_template_link_uri_content
      '<%= link_uri :ruby_home do |out| out << "should be picked up." end %>'
    end

    def view_template_action
      '<%= action :foo %>'
    end

    def view_template_action_content
      '<%= action :foo do |out| out << "should be picked up." end %>'
    end

    def view_template_frame
      '<%= frame :foo %>'
    end

    def view_template_frame_content_ignored
      '<%= frame :foo do |out| out << "should be ignored." end %>'
    end

    def view_template_frame_uri
      '<%= frame_uri :ruby_home %>'
    end

    def view_template_frame_uri_content_ignored
      '<%= frame_uri :ruby_home do |out| out << "should be ignored." end %>'
    end

    def view_template_import
      '[<%= import :foo %>]'
    end

    def view_template_import_content
      '<%= import :bar do |out| out << "should be picked up." end %>'
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

    def view_template_password
      '<%= password :foo %>'
    end

    def view_template_password_value
      '<%= password :bar %>'
    end

    def view_template_password_content_ignored
      '<%= password :foo do |out| "should be ignored." end %>'
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

    def view_template_hidden
      '<%= hidden :foo %>'
    end

    def view_template_hidden_value
      '<%= hidden :bar %>'
    end

    def view_template_hidden_content_ignored
      '<%= hidden :foo do |out| out << "should be ignored." end %>'
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

    def view_template_radio
      '<%= radio :foo, "apple" %>'
    end

    def view_template_radio_checked
      '<%= radio :foo, "banana" %>'
    end

    def view_template_radio_content_ignored
      '<%= radio :foo, "apple" do |out| out << "should be ignored." end %>'
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

    def view_template_textarea
      '<%= textarea :foo %>'
    end

    def view_template_textarea_value
      '<%= textarea :bar %>'
    end

    def view_template_textarea_content_ignored
      '<%= textarea :foo do |out| out << "should be ignored." end %>'
    end
  end
end
