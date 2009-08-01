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
      @r = Gluon::RequestResponseContext.new(Rack::Request.new(@env), Rack::Response.new)
      @po = Gluon::PresentationObject.new(@c, @r, @template_engine)
    end

    def test_value
      @Controller.class_eval{
        gluon_value_reader :foo
        attr_writer :foo
      }
      @c.foo = 'Hello world.'
      assert_equal('Hello world.', @po.gluon(:foo))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
