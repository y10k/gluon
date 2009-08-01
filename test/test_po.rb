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
      @template_engine = Gluon::TemplateEngine.new
      @env = Rack::MockRequest.env_for('http://www.foo.com/run.cgi')
      @env[:gluon_script_name] = @env['SCRIPT_NAME']
      @cmap = Gluon::ClassMap.new
      @r = Gluon::RequestResponseContext.new(Rack::Request.new(@env), Rack::Response.new)
      @r.cmap = @cmap
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

      component = Class.new
      component.class_eval{
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

    def test_link_class
      foo = Class.new
      foo.class_eval{ include Gluon::Controller }
      @cmap.mount(foo, '/halo')

      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo
      }
      @c.foo = foo

      assert_equal('<a href="/halo">Hello world.</a>',
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
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
