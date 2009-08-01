#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class PresentationObjectTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @Controller = Class.new
      @Controller.extend(Gluon::Component)
      @c = @Controller.new
      @env = Rack::MockRequest.env_for('http://www.foo.com/run.cgi')
      @env[:gluon_script_name] = @env['SCRIPT_NAME']
      @cmap = Gluon::ClassMap.new
      @r = Gluon::RequestResponseContext.new(Rack::Request.new(@env), Rack::Response.new)
      @r.cmap = @cmap
      @template_engine = Gluon::TemplateEngine.new
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

    def test_cond
      @Controller.class_eval{
        attr_writer :foo

        def foo?
          @foo
        end
        gluon_cond :foo?
      }
      @c.foo = true
      assert_equal('HALO', @po.gluon(:foo?) {|v| v << 'HALO' })
    end

    def test_cond_not
      @Controller.class_eval{
        attr_writer :foo

        def foo?
          @foo
        end
        gluon_cond :foo?
      }
      @c.foo = false
      assert_equal('', @po.gluon(:foo?) {|v| v << 'HALO' })
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
                   @po.gluon(:foo) {|v| v << '[' << @po.gluon(:bar) << ']' })
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
      assert_equal('<a href="/run.cgi?foo[0].bar"></a>' +
                   '<input type="submit" name="foo[0].baz" />'+
                   '<a href="/run.cgi?foo[1].bar"></a>' +
                   '<input type="submit" name="foo[1].baz" />'+
                   '<a href="/run.cgi?foo[2].bar"></a>' +
                   '<input type="submit" name="foo[2].baz" />',
                   @po.gluon(:foo) {|v| v << @po.gluon(:bar) << @po.gluon(:baz) })
    end

    def test_link_class
      foo = Class.new{ include Gluon::Controller }
      @cmap.mount(foo, '/halo')

      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo
      }
      @c.foo = foo

      assert_equal('<a href="/halo">Hello world.</a>',
                   @po.gluon(:foo) {|v| v << "Hello world." })
    end

    def test_link_class_args
      foo = Class.new{
        include Gluon::Controller
        gluon_path_filter %r"^/(\d\d\d\d)-(\d\d)-(\d\d)$" do |year, mon, day|
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
                   @po.gluon(:foo) {|v| v << "Hello world." })
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
                   @po.gluon(:foo) {|v| v << 'Hello world.' })
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
                   @po.gluon(:foo) {|v| v << 'Hello world.' })
    end

    def test_action
      @Controller.class_eval{
        def foo
        end
        gluon_action :foo
      }
      assert_equal('<a href="/run.cgi?foo">Hello world.</a>',
                   @po.gluon(:foo) {|v| v << 'Hello world.' })
    end

    def test_frame
      @Controller.class_eval{
        attr_writer :foo
        gluon_frame_reader :foo
      }
      @c.foo = '/halo'
      assert_equal('<frame src="/halo" />', @po.gluon(:foo))
    end

    def test_import
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def self.page_encoding
          Encoding::UTF_8
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + '.test_import.rhtml')
        end

        def initialize(messg)
          @bar = messg
        end

        gluon_value_reader :bar
      }

      @c.foo = component.new('Hello world.')
      assert_equal('Hello world.', @po.gluon(:foo))
    end

    def test_import_action
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }

      component = Class.new{
        extend Gluon::Component

        def self.page_encoding
          Encoding::UTF_8
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + '.test_import_action.rhtml')
        end

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

        def self.page_encoding
          Encoding::UTF_8
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + '.test_content.rhtml')
        end
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      assert_equal('Hello world.', @po.gluon(:foo) {|v| v << 'Hello world.' })
    end

    def test_content_block
      component = Class.new{
        extend Gluon::Component

        def self.page_encoding
          Encoding::UTF_8
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + '.test_content_block.rhtml')
        end
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

        def self.page_encoding
          Encoding::UTF_8
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + '.test_content_block_ignored.rhtml')
        end
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      assert_equal('Hello world.', @po.gluon(:foo) {|v| v << 'Hello world.' })
    end

    def test_content_not_defined
      component = Class.new{
        extend Gluon::Component

        def self.page_encoding
          Encoding::UTF_8
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + '.test_content_not_defined.rhtml')
        end
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

    def test_text
      @Controller.class_eval{
        gluon_text_accessor :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('<input type="text" name="foo" value="Hello world." />', @po.gluon(:foo))
    end

    def test_passwd
      @Controller.class_eval{
        gluon_passwd_accessor :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('<input type="password" name="foo" value="Hello world." />', @po.gluon(:foo))
    end

    def test_hidden
      @Controller.class_eval{
        gluon_hidden_accessor :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('<input type="hidden" name="foo" value="Hello world." />', @po.gluon(:foo))
    end

    def test_checkbox_checked
      @Controller.class_eval{
        gluon_checkbox_accessor :foo
      }
      @c.foo = true
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input type="checkbox" name="foo" checked="checked" />',
                   @po.gluon(:foo))
    end

    def test_checkbox_not_checked
      @Controller.class_eval{
        gluon_checkbox_accessor :foo
      }
      @c.foo = false
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input type="checkbox" name="foo" />',
                   @po.gluon(:foo))
    end

    def test_checkbox_valule
      @Controller.class_eval{
        gluon_checkbox_accessor :foo, :value => 'HALO'
      }
      @c.foo = true
      assert_equal('<input type="hidden" name="foo:checkbox" value="submit" style="display: none" />' +
                   '<input type="checkbox" name="foo" value="HALO" checked="checked" />',
                   @po.gluon(:foo))
    end

    def test_radio
      @Controller.class_eval{
        gluon_radio_accessor :foo, %w[ Apple Banana Orange ]
      }
      @c.foo = 'Banana'
      assert_equal('<input type="radio" name="foo" value="Apple" />', @po.gluon(:foo, 'Apple'))
      assert_equal('<input type="radio" name="foo" value="Banana" checked="checked" />', @po.gluon(:foo, 'Banana'))
      assert_equal('<input type="radio" name="foo" value="Orange" />', @po.gluon(:foo, 'Orange'))
    end

    def test_radio_not_checked
      @Controller.class_eval{
        gluon_radio_accessor :foo, %w[ Apple Banana Orange ]
      }
      @c.foo = nil
      assert_equal('<input type="radio" name="foo" value="Apple" />', @po.gluon(:foo, 'Apple'))
      assert_equal('<input type="radio" name="foo" value="Banana" />', @po.gluon(:foo, 'Banana'))
      assert_equal('<input type="radio" name="foo" value="Orange" />', @po.gluon(:foo, 'Orange'))
    end

    def test_radio_unexpected_value
      @Controller.class_eval{
        gluon_radio_accessor :foo, %w[ Apple Banana Orange ]
      }
      @c.foo = 'Banana'
      ex = assert_raise(ArgumentError) { @po.gluon(:foo, 'Pineapple') }
      assert_match(/^unexpected value/, ex.message)
      assert_match(/Pineapple/, ex.message)
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

    def test_select_multiple
      @Controller.class_eval{
        gluon_select_accessor :foo, %w[ Apple Banana Orange ], :multiple => true
      }
      @c.foo = %w[ Apple Orange ]
      assert_equal('<select name="foo" multiple="multiple">' +
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
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
