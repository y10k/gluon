#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class ERBViewTest < Test::Unit::TestCase
    def setup
      @Controller = Class.new{ extend Gluon::Component }
      @c = @Controller.new
      @env = Rack::MockRequest.env_for('http://www.foo.com/run.cgi')
      @env[:gluon_root_script_name] = @env['SCRIPT_NAME']
      @cmap = Gluon::ClassMap.new
      @r = Gluon::RequestResponseContext.new(Rack::Request.new(@env), Rack::Response.new)
      @r.cmap = @cmap
      @template_dir = 'test_erbview.template_dir'
      @template_engine = Gluon::TemplateEngine.new(@template_dir)
      @po = Gluon::PresentationObject.new(@c, @r, @template_engine)
    end

    def mkpath(name)
      File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + ".#{name}.erb")
    end
    private :mkpath

    def caller_test_name
      for at in caller
        if (at =~ /^(.+?):(\d+)(?::in `(.*)')?/) then
          method_name = $3
          if (method_name =~ /^test_/) then
            return method_name
          end
        end
      end

      raise "not in test-case."
    end
    private :caller_test_name

    def template_render(inline_template)
      caller_test_name
      @template_engine.render(@po, @r, Gluon::ERBView,
                              __ENCODING__, mkpath(caller_test_name), inline_template)
    end
    private :template_render

    def test_plain_text
      assert_equal('Hello world.', template_render('Hello world.'))
    end

    def test_gluon
      @Controller.class_eval{
        attr_writer :foo
        gluon_value_reader :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('Hello world.', template_render('<% gluon :foo %>'))
    end

    def test_gluon_nested
      @Controller.class_eval{
        attr_writer :foo
        gluon_link_reader :foo
        attr_writer :bar
        gluon_value_reader :bar
      }
      @c.foo = '/halo'
      @c.bar = 'Hello world.'
      assert_equal('<a href="/halo">Hello world.</a>',
                   template_render('<% gluon :foo do %><% gluon :bar %><% end %>'))
    end

    def test_gluon_content
      component = Class.new{
        extend Gluon::Component

        def self.page_encoding
          __ENCODING__
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + ".test_gluon_content.component.erb")
        end
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      assert_equal('[Hello world.]',
                   template_render('<% gluon :foo do %>Hello world.<% end %>'))
    end

    def test_gluon_content_block
      component = Class.new{
        extend Gluon::Component

        def self.page_encoding
          __ENCODING__
        end

        def self.page_template
          File.join(File.dirname(__FILE__),
                    File.basename(__FILE__, '.rb') + ".test_gluon_content_block.component.erb")
        end
      }

      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      @c.foo = component.new

      assert_equal('[Hello world.]', template_render('<% gluon :foo %>'))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
