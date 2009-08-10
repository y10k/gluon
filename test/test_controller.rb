#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class ControllerTest < Test::Unit::TestCase
    def setup
      @Controller = Class.new{ include Gluon::Controller }
    end

    def test_gluon_path_filter
      @Controller.class_eval{ gluon_path_filter %r"^/foo/([^/]+)$" }
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(@Controller))
    end

    def test_gluon_path_filter_inherited
      @Controller.class_eval{ gluon_path_filter %r"^/foo/([^/]+)$" }
      subclass = Class.new(@Controller)
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(subclass))
    end

    def test_gluon_path_block
      @Controller.class_eval{
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format("/%04d-%02d-%02d", year, mon, day)
        end
      }
      block = Gluon::Controller.find_path_block(@Controller)
      assert_equal('/1975-11-19', block.call(1975, 11, 19))
    end

    def test_gluon_path_block_inherited
      @Controller.class_eval{
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format("/%04d-%02d-%02d", year, mon, day)
        end
      }
      subclass = Class.new(@Controller)
      block = Gluon::Controller.find_path_block(subclass)
      assert_equal('/1975-11-19', block.call(1975, 11, 19))
    end

    def test_gluon_value
      @Controller.class_eval{ gluon_value_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:value, entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_value2
      @Controller.class_eval{
        gluon_value_reader :foo
        gluon_value_reader :bar
      }
      assert(entry = Gluon::Controller.find_view_export(@Controller))

      assert_equal(:value, entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))

      assert_equal(:value, entry[:bar][:type])
      assert_equal(true, (@Controller.public_method_defined? :bar))
      assert_equal(false, (@Controller.public_method_defined? :bar=))
    end

    def test_gluon_value_inherited
      @Controller.class_eval{ gluon_value_reader :foo }
      subclass = Class.new(@Controller)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:value, entry[:foo][:type])
    end

    def test_gluon_cond
      @Controller.class_eval{ gluon_cond_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:cond, entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_cond_inherited
      @Controller.class_eval{ gluon_cond_reader :foo }
      subclass = Class.new(@Controller)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:cond, entry[:foo][:type])
    end

    def test_gloun_cond_not
      @Controller.class_eval{
        attr_reader :foo
        gluon_cond_not :foo
      }
      assert(entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:cond, entry[:not_foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :not_foo))
      assert_equal(false, (@Controller.public_method_defined? :not_foo=))
    end

    def test_gluon_foreach
      @Controller.class_eval{ gluon_foreach_reader :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:foreach, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:foreach, form_entry[:foo][:type])
      assert(action_entry = Gluon::Controller.find_action_export(@Controller))
      assert_equal(:foreach, action_entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_foreach_inherited
      @Controller.class_eval{ gluon_foreach_reader :foo }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:foreach, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:foreach, form_entry[:foo][:type])
      assert(action_entry = Gluon::Controller.find_action_export(subclass))
      assert_equal(:foreach, action_entry[:foo][:type])
    end

    def test_gluon_foreach_form_params
      @Controller.class_eval{
        def initialize
          @foo = Array.new(3)
        end

        gluon_foreach_reader :foo
      }

      component = Class.new
      component.class_eval{
        extend Gluon::Component
        gluon_text_accessor :bar
      }

      c = @Controller.new
      c.foo[0] = component.new
      c.foo[1] = component.new
      c.foo[2] = component.new

      Gluon::Controller.set_form_params(c, {
                                          'foo[0].bar' => 'apple',
                                          'foo[1].bar' => 'banana',
                                          'foo[2].bar' => 'orange'
                                        })

      assert_equal('apple', c.foo[0].bar)
      assert_equal('banana', c.foo[1].bar)
      assert_equal('orange', c.foo[2].bar)
    end

    def test_gluon_foreach_apply_first_action
      @Controller.class_eval{
        def initialize
          @foo = Array.new(3)
        end

        gluon_foreach_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def initialize
          @count = 0
        end

        attr_reader :count

        def bar
          @count += 1
        end
        gluon_action :bar
      }

      c = @Controller.new
      c.foo[0] = component.new
      c.foo[1] = component.new
      c.foo[2] = component.new

      Gluon::Controller.apply_first_action(c, {
                                             'foo[0].bar' => nil,
                                             'foo[1].bar' => nil,
                                             'foo[2].bar' => nil
                                           })

      assert_equal(1, c.foo[0].count)
      assert_equal(0, c.foo[1].count)
      assert_equal(0, c.foo[2].count)
    end

    def test_gluon_link
      @Controller.class_eval{ gluon_link_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:link, entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_link_inherited
      @Controller.class_eval{ gluon_link_reader :foo }
      subclass = Class.new(@Controller)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:link, entry[:foo][:type])
    end

    def test_gluon_action
      @Controller.class_eval{
        def foo
        end
        gluon_action :foo
      }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:action, view_entry[:foo][:type])
      assert(action_entry = Gluon::Controller.find_action_export(@Controller))
      assert_equal(:action, action_entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_action_inherited
      @Controller.class_eval{
        def foo
        end
        gluon_action :foo
      }
      subclass = Class.new(@Controller)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:action, entry[:foo][:type])
    end

    def test_gluon_action_apply_first_action
      @Controller.class_eval{
        def initialize
          @count = 0
        end

        attr_reader :count

        def foo
          @count += 1
        end
        gluon_action :foo
      }
      c = @Controller.new
      Gluon::Controller.apply_first_action(c, { 'foo' => nil })
      assert_equal(1, c.count)
    end

    def test_gluon_frame
      @Controller.class_eval{ gluon_frame_reader :foo }
      assert(entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:frame, entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_frame_inherited
      @Controller.class_eval{ gluon_frame_reader :foo }
      subclass = Class.new(@Controller)
      assert(entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:frame, entry[:foo][:type])
    end

    def test_gluon_import
      @Controller.class_eval{ gluon_import_reader :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:import, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:import, form_entry[:foo][:type])
      assert(action_entry = Gluon::Controller.find_action_export(@Controller))
      assert_equal(:import, action_entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_import_inherited
      @Controller.class_eval{ gluon_import_reader :foo }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:import, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:import, form_entry[:foo][:type])
      assert(action_entry = Gluon::Controller.find_action_export(subclass))
      assert_equal(:import, action_entry[:foo][:type])
    end

    def test_gluon_import_action_params
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }

      component = Class.new
      component.class_eval{
        extend Gluon::Component
        gluon_text_accessor :bar
      }

      c = @Controller.new
      c.foo = component.new

      Gluon::Controller.set_form_params(c, { 'foo.bar' => 'Hello world.' })
      assert_equal('Hello world.', c.foo.bar)
    end

    def test_gluon_import_apply_first_action
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def initialize
          @count = 0
        end

        attr_reader :count

        def bar
          @count += 1
        end
        gluon_action :bar
      }

      c = @Controller.new
      c.foo = component.new

      Gluon::Controller.apply_first_action(c, { 'foo.bar' => nil })
      assert_equal(1, c.foo.count)
    end

    def test_gluon_text
      @Controller.class_eval{ gluon_text_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:text, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:text, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_text_inherited
      @Controller.class_eval{ gluon_text_accessor :foo }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:text, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:text, form_entry[:foo][:type])
    end

    def test_gluon_text_form_params
      @Controller.class_eval{ gluon_text_accessor :foo }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'Hello world.' })
      assert_equal('Hello world.', c.foo)
    end

    def test_gluon_passwd
      @Controller.class_eval{ gluon_passwd_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:passwd, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:passwd, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_passwd_inherited
      @Controller.class_eval{ gluon_passwd_accessor :foo }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:passwd, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:passwd, form_entry[:foo][:type])
    end

    def test_gluon_passwd_form_params
      @Controller.class_eval{ gluon_passwd_accessor :foo }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'Hello world.' })
      assert_equal('Hello world.', c.foo)
    end

    def test_gluon_submit
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo
      }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:submit, view_entry[:foo][:type])
      assert(action_entry = Gluon::Controller.find_action_export(@Controller))
      assert_equal(:submit, action_entry[:foo][:type])
    end

    def test_gluon_submit_inherited
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo
      }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:submit, view_entry[:foo][:type])
      assert(action_entry = Gluon::Controller.find_action_export(subclass))
      assert_equal(:submit, action_entry[:foo][:type])
    end

    def test_gluon_submit_apply_first_action
      @Controller.class_eval{
        def initialize
          @count = 0
        end

        attr_reader :count

        def foo
          @count += 1
        end
        gluon_submit :foo
      }
      c = @Controller.new
      Gluon::Controller.apply_first_action(c, { 'foo' => nil })
      assert_equal(1, c.count)
    end

    def test_gluon_hidden
      @Controller.class_eval{ gluon_hidden_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:hidden, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:hidden, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_hidden_inherited
      @Controller.class_eval{ gluon_hidden_accessor :foo }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:hidden, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:hidden, form_entry[:foo][:type])
    end

    def test_gluon_hidden_form_params
      @Controller.class_eval{ gluon_hidden_accessor :foo }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'Hello world.' })
      assert_equal('Hello world.', c.foo)
    end

    def test_gluon_checkbox
      @Controller.class_eval{ gluon_checkbox_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:checkbox, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:checkbox, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_checkbox_inherited
      @Controller.class_eval{ gluon_checkbox_accessor :foo }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:checkbox, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:checkbox, form_entry[:foo][:type])
    end

    def test_gluon_checkbox_form_params_true
      @Controller.class_eval{ gluon_checkbox_accessor :foo }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo:checkbox' => 'submit', 'foo' => '' })
      assert_equal(true, c.foo)
    end

    def test_gluon_checkbox_form_params_false
      @Controller.class_eval{ gluon_checkbox_accessor :foo }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo:checkbox' => 'submit' })
      assert_equal(false, c.foo)
    end

    def test_gluon_radio
      @Controller.class_eval{ gluon_radio_accessor :foo, %w[ apple banana orange ] }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:radio, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:radio, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_radio_inherited
      @Controller.class_eval{ gluon_radio_accessor :foo, %w[ apple banana orange ] }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:radio, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:radio, form_entry[:foo][:type])
    end

    def test_gluon_radio_form_params
      @Controller.class_eval{ gluon_radio_accessor :foo, %w[ apple banana orange ] }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'banana' })
      assert_equal('banana', c.foo)
    end

    def test_gluon_radio_group
      @Controller.class_eval{ gluon_radio_group_accessor :foo, %w[ apple banana orange ] }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:radio_group, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:radio_group, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_radio_group_inherited
      @Controller.class_eval{ gluon_radio_group_accessor :foo, %w[ apple banana orange ] }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:radio_group, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:radio_group, form_entry[:foo][:type])
    end

    def test_gluon_radio_group_form_params
      @Controller.class_eval{ gluon_radio_group_accessor :foo, %w[ apple banana orange ] }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'banana' })
      assert_equal('banana', c.foo)
    end

    def test_gluon_radio_button
      @Controller.class_eval{ gluon_radio_button_reader :foo, :bar }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:radio_button, view_entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_radio_button_inherited
      @Controller.class_eval{ gluon_radio_button_reader :foo, :bar }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:radio_button, view_entry[:foo][:type])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(false, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_select
      @Controller.class_eval{ gluon_select_accessor :foo, %w[ apple banana orange ] }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:select, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:select, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_select_inherited
      @Controller.class_eval{ gluon_select_accessor :foo, %w[ apple banana orange ] }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:select, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:select, form_entry[:foo][:type])
    end

    def test_gluon_select_form_params
      @Controller.class_eval{ gluon_select_accessor :foo, %w[ apple banana orange ] }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'banana' })
      assert_equal('banana', c.foo)
    end

    def test_gluon_select_form_params_multiple_1
      @Controller.class_eval{
        gluon_select_accessor :foo, %w[ apple banana orange ], :multiple => true
      }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'banana' })
      assert_equal(%w[ banana ], c.foo)
    end

    def test_gluon_select_form_params_multiple_2
      @Controller.class_eval{
        gluon_select_accessor :foo, %w[ apple banana orange ], :multiple => true
      }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => %w[ apple orange ] })
      assert_equal(%w[ apple orange ], c.foo)
    end

    def test_gluon_textarea
      @Controller.class_eval{ gluon_textarea_accessor :foo }
      assert(view_entry = Gluon::Controller.find_view_export(@Controller))
      assert_equal(:textarea, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(@Controller))
      assert_equal(:textarea, form_entry[:foo][:type])
      assert_equal(:foo=, form_entry[:foo][:writer])
      assert_equal(true, (@Controller.public_method_defined? :foo))
      assert_equal(true, (@Controller.public_method_defined? :foo=))
    end

    def test_gluon_textarea_inherited
      @Controller.class_eval{ gluon_textarea_accessor :foo }
      subclass = Class.new(@Controller)
      assert(view_entry = Gluon::Controller.find_view_export(subclass))
      assert_equal(:textarea, view_entry[:foo][:type])
      assert(form_entry = Gluon::Controller.find_form_export(subclass))
      assert_equal(:textarea, form_entry[:foo][:type])
    end

    def test_gluon_textarea_form_params
      @Controller.class_eval{ gluon_textarea_accessor :foo }
      c = @Controller.new
      Gluon::Controller.set_form_params(c, { 'foo' => 'Hello world.' })
      assert_equal('Hello world.', c.foo)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
