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

        def self.page_encoding
          __ENCODING__
        end
      }
      @c = @Controller.new
      @env = Rack::MockRequest.env_for('http://www.foo.com/run.cgi')
      @r = Gluon::RequestResponseContext.new(Rack::Request.new(@env), Rack::Response.new)
      @c.r = @r
      @errors = []
    end

    def test_page_validation_preprocess
      @c.page_validation_preprocess
      assert_nil(@r.validation)
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

    def test_nonnil_OK
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'HALO'

      @c.validation(@errors) do |v|
        v.nonnil :foo
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_nonnil_NG
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = nil

      @c.validation(@errors) do |v|
        v.nonnil :foo
      end

      assert_equal(false, @r.validation)
      assert_equal([ "`foo' should not be nil." ], @errors)
    end

    def test_nonnil_NG_error_message
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = nil

      @c.validation(@errors) do |v|
        v.nonnil :foo, :error => 'foo is NG.'
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'foo is NG.' ], @errors)
    end

    def test_not_empty_OK
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'HALO'

      @c.validation(@errors) do |v|
        v.not_empty :foo
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_not_empty_NG
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = ''

      @c.validation(@errors) do |v|
        v.not_empty :foo
      end

      assert_equal(false, @r.validation)
      assert_equal([ "`foo' should not be empty." ], @errors)
    end

    def test_not_empty_NG_error_message
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = ''

      @c.validation(@errors) do |v|
        v.not_empty :foo, :error => 'foo is NG.'
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'foo is NG.' ], @errors)
    end

    def test_not_empty_NG_nil
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = nil

      @c.validation(@errors) do |v|
        v.not_empty :foo
      end

      assert_equal(false, @r.validation)
      assert_equal([ "`foo' should not be empty." ], @errors)
    end

    def test_not_blank_OK
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'HALO'

      @c.validation(@errors) do |v|
        v.not_blank :foo
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_not_blank_NG
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = ' '

      @c.validation(@errors) do |v|
        v.not_blank :foo
      end

      assert_equal(false, @r.validation)
      assert_equal([ "`foo' should not be blank." ], @errors)
    end

    def test_not_blank_NG_error_message
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = ' '

      @c.validation(@errors) do |v|
        v.not_blank :foo, :error => 'foo is NG.'
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'foo is NG.' ], @errors)
    end


    def test_not_blank_NG_nil
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = nil

      @c.validation(@errors) do |v|
        v.not_blank :foo
      end

      assert_equal(false, @r.validation)
      assert_equal([ "`foo' should not be blank." ], @errors)
    end

    def test_encoding_OK
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'あいうえお'.force_encoding(Encoding::ASCII_8BIT)

      @c.validation(@errors) do |v|
        v.encoding :foo
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
      assert_equal(Encoding::UTF_8, @c.foo.encoding)
      assert_equal('あいうえお', @c.foo)
    end

    def test_encoding_NG
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'あいうえお'.force_encoding(Encoding::ASCII_8BIT)

      @c.validation(@errors) do |v|
        v.encoding :foo, :expected_encoding => Encoding::EUC_JP
      end

      assert_equal(false, @r.validation)
      assert_equal([ "encoding of `foo' is not EUC-JP." ], @errors)
      assert_equal(Encoding::EUC_JP, @c.foo.encoding)
    end

    def test_encoding_NG_error_message
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'あいうえお'.force_encoding(Encoding::ASCII_8BIT)

      @c.validation(@errors) do |v|
        v.encoding :foo, :expected_encoding => Encoding::EUC_JP, :error => 'foo is NG.'
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'foo is NG.' ], @errors)
      assert_equal(Encoding::EUC_JP, @c.foo.encoding)
    end

    def test_encoding_NG_nil
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = nil

      @c.validation(@errors) do |v|
        v.encoding :foo
      end

      assert_equal(false, @r.validation)
      assert_equal([ "encoding of `foo' is not UTF-8." ], @errors)
    end

    def test_match_OK
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'HALO'

      @c.validation(@errors) do |v|
        v.match :foo, /^[A-Z]+$/
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_match_NG
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = '123'

      @c.validation(@errors) do |v|
        v.match :foo, /^[A-Z]+$/
      end

      assert_equal(false, @r.validation)
      assert_equal(1, @errors.length)
      assert_match(/^`foo' should do match to /, @errors[0])
    end

    def test_match_NG_error_message
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = '123'

      @c.validation(@errors) do |v|
        v.match :foo, /^[A-Z]+$/, :error => 'foo is NG.'
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'foo is NG.' ], @errors)
    end

    def test_match_NG_nil
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = nil

      @c.validation(@errors) do |v|
        v.match :foo, /^[A-Z]+$/
      end

      assert_equal(false, @r.validation)
      assert_equal(1, @errors.length)
      assert_match(/^`foo' should do match to /, @errors[0])
    end

    def test_not_match_OK
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = 'HALO'

      @c.validation(@errors) do |v|
        v.not_match :foo, /^\d+$/
      end

      assert_equal(true, @r.validation)
      assert_equal([], @errors)
    end

    def test_not_match_NG
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = '123'

      @c.validation(@errors) do |v|
        v.not_match :foo, /^\d+$/
      end

      assert_equal(false, @r.validation)
      assert_equal(1, @errors.length)
      assert_match(/^`foo' should not do match to /, @errors[0])
    end

    def test_not_match_NG_error_message
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = '123'

      @c.validation(@errors) do |v|
        v.not_match :foo, /^\d+$/, :error => 'foo is NG.'
      end

      assert_equal(false, @r.validation)
      assert_equal([ 'foo is NG.' ], @errors)
    end

    def test_not_match_NG_nil
      @Controller.class_eval{
        attr_accessor :foo
      }
      @c.foo = nil

      @c.validation(@errors) do |v|
        v.not_match :foo, /^\d+$/
      end

      assert_equal(false, @r.validation)
      assert_equal(1, @errors.length)
      assert_match(/^`foo' should not do match to /, @errors[0])
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
