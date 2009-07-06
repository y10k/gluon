#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class ControllerTest < Test::Unit::TestCase
    def setup
      @c = Class.new
      @c.class_eval{
        include Gluon::Controller
      }
    end

    def test_gluon_path_filter
      @c.class_eval{ gluon_path_filter %r"^/foo/([^/]+)$" }
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(@c))
    end

    def test_gluon_path_filter_not_inherited
      subclass = Class.new(@c)
      assert_nil(Gluon::Controller.find_path_filter(subclass))
    end

    def test_gluon_path_block
      @c.class_eval{
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format("/%04d-%02d-%02d", year, mon, day)
        end
      }
      block = Gluon::Controller.find_path_block(@c)
      assert_equal('/1975-11-19', block.call(1975, 11, 19))
    end

    def test_gluon_path_block_not_inherited
      subclass = Class.new(@c)
      assert_nil(Gluon::Controller.find_path_block(subclass))
    end

    def test_gluon_value
      @c.class_eval{ gluon_value_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:value, entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(false, (@c.public_method_defined? :foo=))
    end

    def test_gluon_value_inherited
      @c.class_eval{ gluon_value_reader :foo }
      subclass = Class.new(@c)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:value, entry[:foo][:type])
    end

    def test_gluon_cond
      @c.class_eval{ gluon_cond_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:cond, entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(false, (@c.public_method_defined? :foo=))
    end

    def test_gluon_cond_inherited
      @c.class_eval{ gluon_cond_reader :foo }
      subclass = Class.new(@c)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:cond, entry[:foo][:type])
    end

    def test_gluon_foreach
      @c.class_eval{ gluon_foreach_reader :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:foreach, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:foreach, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(false, (@c.public_method_defined? :foo=))
    end

    def test_gluon_foreach_inherited
      @c.class_eval{ gluon_foreach_reader :foo }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:foreach, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:foreach, form_entry[:foo][:type])
    end

    def test_gluon_link
      @c.class_eval{ gluon_link_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:link, entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(false, (@c.public_method_defined? :foo=))
    end

    def test_gluon_link_inherited
      @c.class_eval{ gluon_link_reader :foo }
      subclass = Class.new(@c)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:link, entry[:foo][:type])
    end

    def test_gluon_action
      @c.class_eval{ gluon_action_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:action, entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(false, (@c.public_method_defined? :foo=))
    end

    def test_gluon_action_inherited
      @c.class_eval{ gluon_action_reader :foo }
      subclass = Class.new(@c)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:action, entry[:foo][:type])
    end

    def test_gluon_frame
      @c.class_eval{ gluon_frame_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:frame, entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(false, (@c.public_method_defined? :foo=))
    end

    def test_gluon_frame_inherited
      @c.class_eval{ gluon_frame_reader :foo }
      subclass = Class.new(@c)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:frame, entry[:foo][:type])
    end

    def test_gluon_import
      @c.class_eval{ gluon_import_reader :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:import, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:import, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(false, (@c.public_method_defined? :foo=))
    end

    def test_gluon_import_inherited
      @c.class_eval{ gluon_import_reader :foo }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:import, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:import, form_entry[:foo][:type])
    end

    def test_gluon_text
      @c.class_eval{ gluon_text_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:text, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:text, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(true, (@c.public_method_defined? :foo=))
    end

    def test_gluon_text_inherited
      @c.class_eval{ gluon_text_accessor :foo }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:text, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:text, form_entry[:foo][:type])
    end

    def test_gluon_passwd
      @c.class_eval{ gluon_passwd_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:passwd, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:passwd, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(true, (@c.public_method_defined? :foo=))
    end

    def test_gluon_passwd_inherited
      @c.class_eval{ gluon_passwd_accessor :foo }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:passwd, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:passwd, form_entry[:foo][:type])
    end

    def test_gluon_submit
      @c.class_eval{
        def foo
        end
        gluon_submit :foo
      }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:submit, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:submit, form_entry[:foo][:type])
    end

    def test_gluon_submit_inherited
      @c.class_eval{
        def foo
        end
        gluon_submit :foo
      }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:submit, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:submit, form_entry[:foo][:type])
    end

    def test_gluon_hidden
      @c.class_eval{ gluon_hidden_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:hidden, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:hidden, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(true, (@c.public_method_defined? :foo=))
    end

    def test_gluon_hidden_inherited
      @c.class_eval{ gluon_hidden_accessor :foo }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:hidden, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:hidden, form_entry[:foo][:type])
    end

    def test_gluon_checkbox
      @c.class_eval{ gluon_checkbox_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:checkbox, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:checkbox, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(true, (@c.public_method_defined? :foo=))
    end

    def test_gluon_checkbox_inherited
      @c.class_eval{ gluon_checkbox_accessor :foo }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:checkbox, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:checkbox, form_entry[:foo][:type])
    end

    def test_gluon_radio
      @c.class_eval{ gluon_radio_accessor :foo, %w[ apple banana orange ] }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:radio, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:radio, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(true, (@c.public_method_defined? :foo=))
    end

    def test_gluon_radio_inherited
      @c.class_eval{ gluon_radio_accessor :foo, %w[ apple banana orange ] }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:radio, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:radio, form_entry[:foo][:type])
    end

    def test_gluon_select
      @c.class_eval{ gluon_select_accessor :foo, %w[ apple banana orange ] }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:select, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:select, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(true, (@c.public_method_defined? :foo=))
    end

    def test_gluon_select_inherited
      @c.class_eval{ gluon_select_accessor :foo, %w[ apple banana orange ] }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:select, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:select, form_entry[:foo][:type])
    end

    def test_gluon_textarea
      @c.class_eval{ gluon_textarea_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@c))
      assert_equal(:textarea, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@c))
      assert_equal(:textarea, form_entry[:foo][:type])
      assert_equal(true, (@c.public_method_defined? :foo))
      assert_equal(true, (@c.public_method_defined? :foo=))
    end

    def test_gluon_textarea_inherited
      @c.class_eval{ gluon_textarea_accessor :foo }
      subclass = Class.new(@c)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:textarea, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:textarea, form_entry[:foo][:type])
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
