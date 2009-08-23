#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class ValidationTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @Controller = Class.new{
        include Gluon::Controller
        include Gluon::Validation
      }
      @c = @Controller.new
      @env = Rack::MockRequest.env_for('http://www.foo.com/run.cgi')
      @r = Gluon::RequestResponseContext.new(Rack::Request.new(@env), Rack::Response.new)
      @c.r = @r
      @errors = []
    end

    def test_validate_OK
      @c.validation(@errors) do |v|
        v.validate 'test error.' do
          true
        end
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_validate_NG
      @c.validation(@errors) do |v|
        v.validate 'test error.' do
          false
        end
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'test error.' ], @errors)
    end

    def test_validate_NG_2
      @c.validation(@errors) do |v|
        v.validate 'test error-1.' do
          true
        end
        v.validate 'test error-2.' do
          false
        end
        v.validate 'test error-3.' do
          true
        end
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'test error-2.' ], @errors)
    end

    def test_foreach_validate_OK
      @Controller.class_eval{
        attr_writer :foo
        gluon_foreach_reader :foo
      }

      component = Class.new{
        def initialize(name, bar)
          @name = name
          @bar = bar
        end

        attr_reader :name

        def bar?
          @bar
        end
      }

      @c.foo = [
        component.new('a', true),
        component.new('b', true),
        component.new('c', true)
      ]

      @c.validation(@errors) do |v|
        v.foreach :foo do |v|
          v.validate "test error: #{v.controller.name}" do
            v.controller.bar?
          end
        end
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_foreach_validate_NG
      @Controller.class_eval{
        attr_writer :foo
        gluon_foreach_reader :foo
      }

      component = Class.new{
        def initialize(name, bar)
          @name = name
          @bar = bar
        end

        attr_reader :name

        def bar?
          @bar
        end
      }

      @c.foo = [
        component.new('a', true),
        component.new('b', false),
        component.new('c', true)
      ]

      @c.validation(@errors) do |v|
        v.foreach :foo do |v|
          v.validate "test error: #{v.controller.name}" do
            v.controller.bar?
          end
        end
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'test error: b' ], @errors)
    end

    def test_foreach_validate_NG_all
      @Controller.class_eval{
        attr_writer :foo
        gluon_foreach_reader :foo
      }

      component = Class.new{
        def initialize(name, bar)
          @name = name
          @bar = bar
        end

        attr_reader :name

        def bar?
          @bar
        end
      }

      @c.foo = [
        component.new('a', false),
        component.new('b', false),
        component.new('c', false)
      ]

      @c.validation(@errors) do |v|
        v.foreach :foo do |v|
          v.validate "test error: #{v.controller.name}" do
            v.controller.bar?
          end
        end
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'test error: a', 'test error: b', 'test error: c' ], @errors)
    end

    def test_import_validate_OK
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      component = Class.new
      @c.foo = component.new

      @c.validation(@errors) do |v|
        v.import :foo do |v|
          v.validate 'test error.' do
            true
          end
        end
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_import_validate_NG
      @Controller.class_eval{
        attr_writer :foo
        gluon_import_reader :foo
      }
      component = Class.new
      @c.foo = component.new

      @c.validation(@errors) do |v|
        v.import :foo do |v|
          v.validate 'test error.' do
            false
          end
        end
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'test error.' ], @errors)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
