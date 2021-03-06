#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class PresentationObjectTest < Test::Unit::TestCase
    def setup
      @Controller = Class.new{ extend Gluon::Component }
      @c = @Controller.new
      @env = Rack::MockRequest.env_for('http://www.foo.com/run.cgi')
      @env[:gluon_root_script_name] = @env['SCRIPT_NAME']
      @cmap = Gluon::ClassMap.new
      @r = Gluon::RequestResponseContext.new(Rack::Request.new(@env), Rack::Response.new)
      @r.cmap = @cmap
      @template_dir = 'test_po.template_dir'
      @template_engine = Gluon::TemplateEngine.new(@template_dir)
      @po = Gluon::PresentationObject.new(@c, @r, @template_engine)
    end

    def test_value
      @Controller.class_eval{
        attr_writer :foo
        gluon_value_reader :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('Hello world.', @po.gluon(:foo))
    end

    def test_value_escape
      @Controller.class_eval{
        attr_writer :foo
        gluon_value_reader :foo
      }
      @c.foo = '&<>'
      assert_equal('&amp;&lt;&gt;', @po.gluon(:foo))
    end

    def test_value_no_escape
      @Controller.class_eval{
        attr_writer :foo
        gluon_value_reader :foo, :escape => false
      }
      @c.foo = '&<>'
      assert_equal('&<>', @po.gluon(:foo))
    end

    def test_value_autoid_prefix
      @Controller.class_eval{
        attr_writer :foo
        gluon_value_reader :foo, :autoid_prefix => true
      }
      @c.foo = 'foo'
      assert_equal('foo', @po.gluon(:foo))
    end

    def test_cond
      @Controller.class_eval{
        attr_writer :foo

        def foo?
          @foo
        end
        gluon_cond :foo?
      }

      @c.foo = true
      assert_equal('HALO', @po.gluon(:foo?) { 'HALO' })

      @c.foo = false
      assert_equal('', @po.gluon(:foo?) { 'HALO' })
    end

    def test_cond_not
      @Controller.class_eval{
        attr_writer :foo

        def foo?
          @foo
        end
        gluon_cond_not :foo?
      }

      @c.foo = true
      assert_equal('', @po.gluon(:not_foo?) { 'HALO' })

      @c.foo = false
      assert_equal('HALO', @po.gluon(:not_foo?) { 'HALO' })
    end

    def test_foreach
      @Controller.class_eval{
        attr_writer :foo
        gluon_foreach_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def initialize(text)
          @bar = text
        end

        gluon_value_reader :bar
      }

      @c.foo = [
        component.new('Apple'),
        component.new('Banana'),
        component.new('Orange')
      ]
      assert_equal('[Apple][Banana][Orange]',
                   @po.gluon(:foo) { '[' << @po.gluon(:bar) << ']' })
    end

    def test_foreach_value_autoid_prefix
      @Controller.class_eval{
        attr_writer :foo
        gluon_foreach_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def initialize(text)
          @bar = text
        end

        gluon_value_reader :bar, :autoid_prefix => true
      }

      @c.foo = [ component.new('apple'), component.new('banana') ]
      assert_equal('[foo(0).apple][foo(1).banana]',
                   @po.gluon(:foo) { '[' << @po.gluon(:bar) << ']'  })
    end

    def test_foreach_action
      @Controller.class_eval{
        attr_writer :foo
        gluon_foreach_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def bar
        end
        gluon_action :bar

        def baz
        end
        gluon_submit :baz
      }

      @c.foo = [
        component.new,
        component.new,
        component.new
      ]
      assert_equal('<a href="/run.cgi?foo(0).bar"></a>' +
                   '<input type="submit" name="foo(0).baz" />'+
                   '<a href="/run.cgi?foo(1).bar"></a>' +
                   '<input type="submit" name="foo(1).baz" />'+
                   '<a href="/run.cgi?foo(2).bar"></a>' +
                   '<input type="submit" name="foo(2).baz" />',
                   @po.gluon(:foo) { @po.gluon(:bar) << @po.gluon(:baz) })
    end

    def test_foreach_action_autoid_true
      @Controller.class_eval{
        attr_writer :foo
        gluon_foreach_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def bar
        end
        gluon_action :bar, :autoid => true

        def baz
        end
        gluon_submit :baz, :autoid => true
      }

      @c.foo = [
        component.new,
        component.new,
        component.new
      ]
      assert_equal('<a id="foo(0).bar" href="/run.cgi?foo(0).bar">id: foo(0).bar</a>' +
                   '<input id="foo(0).baz" type="submit" name="foo(0).baz" />' + 
                   '<label for="foo(0).baz">baz</label>' +
                   '<a id="foo(1).bar" href="/run.cgi?foo(1).bar">id: foo(1).bar</a>' +
                   '<input id="foo(1).baz" type="submit" name="foo(1).baz" />'+
                   '<label for="foo(1).baz">baz</label>' +
                   '<a id="foo(2).bar" href="/run.cgi?foo(2).bar">id: foo(2).bar</a>' +
                   '<input id="foo(2).baz" type="submit" name="foo(2).baz" />' +
                   '<label for="foo(2).baz">baz</label>',
                   @po.gluon(:foo) {
                     @po.gluon(:bar) { 'id: ' << @po.gluon(:bar_id) } <<
                       @po.gluon(:baz) << '<label for="' << @po.gluon(:baz_id) << '">baz</label>'
                   })
    end

    def test_link_class
      foo = Class.new(Gluon::Controller)
      @cmap.mount(foo, '/halo')

      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo
      }
      @c.foo = foo

      assert_equal('<a href="/halo">Hello world.</a>',
                   @po.gluon(:foo) { "Hello world." })
    end

    def test_link_class_args
      foo = Class.new(Gluon::Controller) {
        gluon_path_match %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
          format('/%04d-%02d-%02d', year, mon, day)
        end
      }
      @cmap.mount(foo, '/halo')

      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo
      }
      @c.foo = foo, [ 1975, 11, 19 ]

      assert_equal('<a href="/halo/1975-11-19">Hello world.</a>',
                   @po.gluon(:foo) { "Hello world." })
    end

    def test_link_url
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :text => 'Hello world.'
      }
      @c.foo = '/halo'
      assert_equal('<a href="/halo">Hello world.</a>', @po.gluon(:foo))
    end

    def test_link_text_method
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :text => :bar

        def bar
          'Hello world.'
        end
      }
      @c.foo = '/halo'
      assert_equal('<a href="/halo">Hello world.</a>', @po.gluon(:foo))
    end

    def test_link_attrs
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :attrs => { 'id' => 'foo' }
      }
      @c.foo = '/halo'
      assert_equal('<a href="/halo" id="foo">Hello world.</a>',
                   @po.gluon(:foo) { 'Hello world.' })
    end

    def test_link_attrs_ignore_nil
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :attrs => { 'id' => nil }
      }
      @c.foo = '/halo'
      assert_equal('<a href="/halo">Hello world.</a>',
                   @po.gluon(:foo) { 'Hello world.' })
    end

    def test_link_attrs_method
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :attrs => { 'style' => :link_style }

        def link_style
          'font-weight: bold'
        end
      }
      @c.foo = '/halo'
      assert_equal('<a href="/halo" style="font-weight: bold">Hello world.</a>',
                   @po.gluon(:foo) { 'Hello world.' })
    end

    def test_link_attrs_method2
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :attrs => :attributes

        def attributes
          { 'id' => 'foo', 'style' => 'font-weight: bold' }
        end
      }
      @c.foo = '/halo'
      assert_equal('<a href="/halo" id="foo" style="font-weight: bold">Hello world.</a>',
                   @po.gluon(:foo) { 'Hello world.' })
    end

    def test_link_autoid_true
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :autoid => true
      }
      @c.foo = '/halo'
      assert_equal('<a id="foo" href="/halo">id: foo</a>',
                   @po.gluon(:foo) { 'id: ' << @po.gluon(:foo_id) })
    end

    def test_link_autoid_value
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo, :autoid => 'apple'
      }
      @c.foo = '/halo'
      assert_equal('<a id="apple" href="/halo">id: apple</a>',
                   @po.gluon(:foo) { 'id: ' << @po.gluon(:foo_id) })
    end

    def test_action
      @Controller.class_eval{
        def foo
        end
        gluon_action :foo
      }
      assert_equal('<a href="/run.cgi?foo">Hello world.</a>',
                   @po.gluon(:foo) { 'Hello world.' })
    end

    def test_action_autoid_true
      @Controller.class_eval{
        def foo
        end
        gluon_action :foo, :autoid => true
      }
      assert_equal('<a id="foo" href="/run.cgi?foo">id: foo</a>',
                   @po.gluon(:foo) { 'id: ' << @po.gluon(:foo_id) })
    end

    def test_action_autoid_valule
      @Controller.class_eval{
        def foo
        end
        gluon_action :foo, :autoid => 'apple'
      }
      assert_equal('<a id="apple" href="/run.cgi?foo">id: apple</a>',
                   @po.gluon(:foo) { 'id: ' << @po.gluon(:foo_id) })
    end

    def test_frame
      @Controller.class_eval{
        attr_writer :foo
        gluon_frame_reader :foo
      }
      @c.foo = '/halo'
      assert_equal('<frame src="/halo" />', @po.gluon(:foo))
    end

    def test_frame_autoid_true
      @Controller.class_eval{
        attr_writer :foo
        gluon_frame_reader :foo, :autoid => true
      }
      @c.foo = '/halo'
      assert_equal('<frame id="foo" src="/halo" />, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_frame_autoid_value
      @Controller.class_eval{
        attr_writer :foo
        gluon_frame_reader :foo, :autoid => 'apple'
      }
      @c.foo = '/halo'
      assert_equal('<frame id="apple" src="/halo" />, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_import
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def_page_encoding __ENCODING__

        def_page_template File.join(File.dirname(__FILE__),
                                    File.basename(__FILE__, '.rb') + 
                                    '.test_import.erb')

        def initialize(messg)
          @bar = messg
        end

        gluon_value_reader :bar
      }

      @c.foo = component.new('Hello world.')
      assert_equal('Hello world.', @po.gluon(:foo))
    end

    def test_import_value_autoid_prefix
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def_page_encoding __ENCODING__

        def_page_template File.join(File.dirname(__FILE__),
                                    File.basename(__FILE__, '.rb') + 
                                    '.test_import_autoid_value.erb')

        def initialize(messg)
          @bar = messg
        end

        gluon_value_reader :bar, :autoid_prefix => true
      }

      @c.foo = component.new('apple')
      assert_equal('foo.apple', @po.gluon(:foo))
    end

    def test_import_action
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def_page_encoding __ENCODING__

        def_page_template File.join(File.dirname(__FILE__),
                                    File.basename(__FILE__, '.rb') +
                                    '.test_import_action.erb')

        def bar
        end
        gluon_action :bar

        def baz
        end
        gluon_submit :baz
      }

      @c.foo = component.new
      assert_equal('<a href="/run.cgi?foo.bar"></a>' +
                   '<input type="submit" name="foo.baz" />',
                   @po.gluon(:foo))
    end

    def test_content
      component = Class.new{
        extend Gluon::Component

        def_page_encoding __ENCODING__

        def_page_template File.join(File.dirname(__FILE__),
                                    File.basename(__FILE__, '.rb') +
                                    '.test_content.erb')
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      assert_equal('Hello world.', @po.gluon(:foo) { 'Hello world.' })
    end

    def test_content_block
      component = Class.new{
        extend Gluon::Component

        def_page_encoding __ENCODING__

        def_page_template File.join(File.dirname(__FILE__),
                                    File.basename(__FILE__, '.rb') +
                                    '.test_content_block.erb')
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      assert_equal('Hello world.', @po.gluon(:foo))
    end

    def test_content_block_ignored
      component = Class.new{
        extend Gluon::Component

        def_page_encoding __ENCODING__

        def_page_template File.join(File.dirname(__FILE__),
                                    File.basename(__FILE__, '.rb') +
                                    '.test_content_block_ignored.erb')
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      assert_equal('Hello world.', @po.gluon(:foo) { 'Hello world.' })
    end

    def test_content_not_defined
      component = Class.new{
        extend Gluon::Component

        def_page_encoding __ENCODING__

        def_page_template File.join(File.dirname(__FILE__),
                                    File.basename(__FILE__, '.rb') +
                                    '.test_content_not_defined.erb')
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      ex = assert_raise(RuntimeError) { @po.gluon(:foo) }
      assert_equal('not defined content.', ex.message)
    end

    def test_submit
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo
      }
      assert_equal('<input type="submit" name="foo" />', @po.gluon(:foo))
    end

    def test_submit_value
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo, :value => 'HALO'
      }
      assert_equal('<input type="submit" name="foo" value="HALO" />', @po.gluon(:foo))
    end

    def test_submit_attrs_bool_true
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo, :attrs => { 'disabled' => true }
      }
      assert_equal('<input type="submit" name="foo" disabled="disabled" />', @po.gluon(:foo))
    end

    def test_submit_attrs_bool_false
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo, :attrs => { 'disabled' => false }
      }
      assert_equal('<input type="submit" name="foo" />', @po.gluon(:foo))
    end

    def test_submit_autoid_true
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo, :autoid => true
      }
      assert_equal('<input id="foo" type="submit" name="foo" />, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_submit_autoid_value
      @Controller.class_eval{
        def foo
        end
        gluon_submit :foo, :autoid => 'apple'
      }
      assert_equal('<input id="apple" type="submit" name="foo" />, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_text
      @Controller.class_eval{
        gluon_text_accessor :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('<input type="text" name="foo" value="Hello world." />', @po.gluon(:foo))
    end

    def test_text_autoid_true
      @Controller.class_eval{
        gluon_text_accessor :foo, :autoid => true
      }
      @c.foo = 'Hello world.'
      assert_equal('<input id="foo" type="text" name="foo" value="Hello world." />, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_text_autoid_value
      @Controller.class_eval{
        gluon_text_accessor :foo, :autoid => 'apple'
      }
      @c.foo = 'Hello world.'
      assert_equal('<input id="apple" type="text" name="foo" value="Hello world." />, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_passwd
      @Controller.class_eval{
        gluon_passwd_accessor :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('<input type="password" name="foo" value="Hello world." />', @po.gluon(:foo))
    end

    def test_passwd_autoid_true
      @Controller.class_eval{
        gluon_passwd_accessor :foo, :autoid => true
      }
      @c.foo = 'Hello world.'
      assert_equal('<input id="foo" type="password" name="foo" value="Hello world." />, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_passwd_autoid_value
      @Controller.class_eval{
        gluon_passwd_accessor :foo, :autoid => 'apple'
      }
      @c.foo = 'Hello world.'
      assert_equal('<input id="apple" type="password" name="foo" value="Hello world." />, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_hidden
      @Controller.class_eval{
        gluon_hidden_accessor :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('<input type="hidden" name="foo" value="Hello world." />', @po.gluon(:foo))
    end

    def test_hidden_autoid_true
      @Controller.class_eval{
        gluon_hidden_accessor :foo, :autoid => true
      }
      @c.foo = 'Hello world.'
      assert_equal('<input id="foo" type="hidden" name="foo" value="Hello world." />, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_hidden_autoid_value
      @Controller.class_eval{
        gluon_hidden_accessor :foo, :autoid => 'apple'
      }
      @c.foo = 'Hello world.'
      assert_equal('<input id="apple" type="hidden" name="foo" value="Hello world." />, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_checkbox_checked
      @Controller.class_eval{
        gluon_checkbox_accessor :foo
      }
      @c.foo = true
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input type="checkbox" name="foo" value="" checked="checked" />',
                   @po.gluon(:foo))
    end

    def test_checkbox_not_checked
      @Controller.class_eval{
        gluon_checkbox_accessor :foo
      }
      @c.foo = false
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input type="checkbox" name="foo" value="" />',
                   @po.gluon(:foo))
    end

    def test_checkbox_value
      @Controller.class_eval{
        gluon_checkbox_accessor :foo, :value => 'HALO'
      }
      @c.foo = true
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input type="checkbox" name="foo" value="HALO" checked="checked" />',
                   @po.gluon(:foo))
    end

    def test_checkbox_autoid_true
      @Controller.class_eval{
        gluon_checkbox_accessor :foo, :autoid => true
      }
      @c.foo = true
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input id="foo" type="checkbox" name="foo" value="" checked="checked" />, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_checkbox_autoid_value
      @Controller.class_eval{
        gluon_checkbox_accessor :foo, :autoid => 'apple'
      }
      @c.foo = true
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input id="apple" type="checkbox" name="foo" value="" checked="checked" />, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_radio_group_button
      @Controller.class_eval{
        gluon_radio_group_accessor :foo, %w[ Apple Banana Orange ]

        def apple
          'Apple'
        end
        gluon_radio_button :apple, :foo

        def banana
          'Banana'
        end
        gluon_radio_button :banana, :foo

        def orange
          'Orange'
        end
        gluon_radio_button :orange, :foo
      }
      @c.foo = 'Banana'
      assert_equal('<input type="radio" name="foo" value="Apple" />',
                   @po.gluon(:foo) { @po.gluon(:apple) })
      assert_equal('<input type="radio" name="foo" value="Banana" checked="checked" />',
                   @po.gluon(:foo) { @po.gluon(:banana) })
      assert_equal('<input type="radio" name="foo" value="Orange" />',
                   @po.gluon(:foo) { @po.gluon(:orange) })
    end

    def test_radio_group_button_autoid_true
      @Controller.class_eval{
        gluon_radio_group_accessor :foo, %w[ Apple Banana Orange ]

        def apple
          'Apple'
        end
        gluon_radio_button :apple, :foo, :autoid => true

        def banana
          'Banana'
        end
        gluon_radio_button :banana, :foo, :autoid => true

        def orange
          'Orange'
        end
        gluon_radio_button :orange, :foo, :autoid => true
      }
      @c.foo = 'Banana'
      assert_equal('<input id="apple" type="radio" name="foo" value="Apple" />, id: apple',
                   @po.gluon(:foo) { @po.gluon(:apple) << ', id: ' << @po.gluon(:apple_id) })
      assert_equal('<input id="banana" type="radio" name="foo" value="Banana" checked="checked" />, id: banana',
                   @po.gluon(:foo) { @po.gluon(:banana) << ', id: ' << @po.gluon(:banana_id) })
      assert_equal('<input id="orange" type="radio" name="foo" value="Orange" />, id: orange',
                   @po.gluon(:foo) { @po.gluon(:orange) << ', id: ' << @po.gluon(:orange_id) })
    end

    def test_radio_group_button_autoid_value
      @Controller.class_eval{
        gluon_radio_group_accessor :foo, %w[ Apple Banana Orange ]

        def apple
          'Apple'
        end
        gluon_radio_button :apple, :foo, :autoid => 'Alice'

        def banana
          'Banana'
        end
        gluon_radio_button :banana, :foo, :autoid => 'Bob'

        def orange
          'Orange'
        end
        gluon_radio_button :orange, :foo, :autoid => 'Kate'
      }
      @c.foo = 'Banana'
      assert_equal('<input id="Alice" type="radio" name="foo" value="Apple" />, id: Alice',
                   @po.gluon(:foo) { @po.gluon(:apple) << ', id: ' << @po.gluon(:apple_id) })
      assert_equal('<input id="Bob" type="radio" name="foo" value="Banana" checked="checked" />, id: Bob',
                   @po.gluon(:foo) { @po.gluon(:banana) << ', id: ' << @po.gluon(:banana_id) })
      assert_equal('<input id="Kate" type="radio" name="foo" value="Orange" />, id: Kate',
                   @po.gluon(:foo) { @po.gluon(:orange) << ', id: ' << @po.gluon(:orange_id) })
    end

    def test_radio_group_button_foreach
      @Controller.class_eval{
        gluon_radio_group_accessor :foo, %w[ Apple Banana Orange ]
        attr_writer :buttons
        gluon_foreach_reader :buttons
      }

      component = Class.new{
        extend Gluon::Component

        def initialize(value)
          @bar = value
        end

        gluon_radio_button_reader :bar, :foo
      }

      @c.foo = 'Banana'
      @c.buttons = [
        component.new('Apple'),
        component.new('Banana'),
        component.new('Orange')
      ]

      assert_equal('<input type="radio" name="foo" value="Apple" />' +
                   '<input type="radio" name="foo" value="Banana" checked="checked" />' +
                   '<input type="radio" name="foo" value="Orange" />',
                   @po.gluon(:foo) {
                     @po.gluon(:buttons) { @po.gluon(:bar) }
                   })
    end

    def test_radio_group_button_not_checked
      @Controller.class_eval{
        gluon_radio_group_accessor :foo, %w[ Apple Banana Orange ]

        def apple
          'Apple'
        end
        gluon_radio_button :apple, :foo

        def banana
          'Banana'
        end
        gluon_radio_button :banana, :foo

        def orange
          'Orange'
        end
        gluon_radio_button :orange, :foo
      }
      @c.foo = nil
      assert_equal('<input type="radio" name="foo" value="Apple" />',
                   @po.gluon(:foo) { @po.gluon(:apple) })
      assert_equal('<input type="radio" name="foo" value="Banana" />',
                   @po.gluon(:foo) { @po.gluon(:banana) })
      assert_equal('<input type="radio" name="foo" value="Orange" />',
                   @po.gluon(:foo) { @po.gluon(:orange) })
    end

    def test_radio_button_not_in_radio_group
      @Controller.class_eval{
        def bar
          'Bar'
        end
        gluon_radio_button :bar, :foo
      }
      ex = assert_raise(RuntimeError) { @po.gluon(:bar) }
      assert_match(/not found a radio group/, ex.message)
      assert_match(/foo/, ex.message)
      assert_match(/radio button/, ex.message)
      assert_match(/bar/, ex.message)
    end

    def test_radio_group_button_unexpected_value
      @Controller.class_eval{
        gluon_radio_group_accessor :foo, %w[ Apple Banana Orange ]

        def bar
          'Bar'
        end
        gluon_radio_button :bar, :foo
      }
      @c.foo = nil
      ex = assert_raise(RuntimeError) { @po.gluon(:foo) { @po.gluon(:bar) } }
      assert_match(/unexpected radio button value/, ex.message)
      assert_match(/Bar/, ex.message)
      assert_match(/bar/, ex.message)
      assert_match(/for radio group/, ex.message)
      assert_match(/foo/, ex.message)
    end

    def test_select
      @Controller.class_eval{
        gluon_select_accessor :foo, %w[ Apple Banana Orange ]
      }
      @c.foo = 'Banana'
      assert_equal('<select name="foo">' +
                   '<option value="Apple">Apple</option>' +
                   '<option value="Banana" selected="selected">Banana</option>' +
                   '<option value="Orange">Orange</option>' +
                   '</select>',
                   @po.gluon(:foo))
    end

    def test_select_autoid_true
      @Controller.class_eval{
        gluon_select_accessor :foo, %w[ Apple Banana Orange ], :autoid => true
      }
      @c.foo = 'Banana'
      assert_equal('<select id="foo" name="foo">' +
                   '<option value="Apple">Apple</option>' +
                   '<option value="Banana" selected="selected">Banana</option>' +
                   '<option value="Orange">Orange</option>' +
                   '</select>, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_select_autoid_value
      @Controller.class_eval{
        gluon_select_accessor :foo, %w[ Apple Banana Orange ], :autoid => 'apple'
      }
      @c.foo = 'Banana'
      assert_equal('<select id="apple" name="foo">' +
                   '<option value="Apple">Apple</option>' +
                   '<option value="Banana" selected="selected">Banana</option>' +
                   '<option value="Orange">Orange</option>' +
                   '</select>, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_select_multiple
      @Controller.class_eval{
        gluon_select_accessor :foo, %w[ Apple Banana Orange ], :multiple => true
      }
      @c.foo = %w[ Apple Orange ]
      assert_equal('<select name="foo[]" multiple="multiple">' +
                   '<option value="Apple" selected="selected">Apple</option>' +
                   '<option value="Banana">Banana</option>' +
                   '<option value="Orange" selected="selected">Orange</option>' +
                   '</select>',
                   @po.gluon(:foo))
    end

    def test_select_assoc_list
      @Controller.class_eval{
        gluon_select_accessor :foo, [ %w[ a Apple ], %w[ b Banana ], %w[ c Orange ] ]
      }
      @c.foo = 'b'
      assert_equal('<select name="foo">' +
                   '<option value="a">Apple</option>' +
                   '<option value="b" selected="selected">Banana</option>' +
                   '<option value="c">Orange</option>' +
                   '</select>',
                   @po.gluon(:foo))
    end

    def test_textarea
      @Controller.class_eval{
        gluon_textarea_accessor :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('<textarea name="foo">Hello world.</textarea>', @po.gluon(:foo))
    end

    def test_textarea_autoid_true
      @Controller.class_eval{
        gluon_textarea_accessor :foo, :autoid => true
      }
      @c.foo = 'Hello world.'
      assert_equal('<textarea id="foo" name="foo">Hello world.</textarea>, id: foo',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_textarea_autoid_value
      @Controller.class_eval{
        gluon_textarea_accessor :foo, :autoid => 'apple'
      }
      @c.foo = 'Hello world.'
      assert_equal('<textarea id="apple" name="foo">Hello world.</textarea>, id: apple',
                   @po.gluon(:foo) << ', id: ' << @po.gluon(:foo_id))
    end

    def test_gluon_no_view_export
      ex = assert_raise(ArgumentError) { @po.gluon(:foo) }
      assert_match(/^no view export:/, ex.message)
      assert_match(/foo/, ex.message)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
