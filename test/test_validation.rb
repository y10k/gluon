#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'

module Gluon::Test
  class ValidatorTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    class DummyController
      attr_writer :c
      gluon_accessor :foo
    end

    def setup
      @controller = DummyController.new
      @errors = []
      @validator = Gluon::Validator.new(@controller, @errors)
    end

    def test_validation_scalar_ok
      @controller.foo = 'HALO'
      result = \
      @validator.validation do
        scalar :foo
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_required_block_ok
      @controller.foo = 'HALO'
      result = \
      @validator.validation do
        required do
          scalar :foo
        end
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_required_block_ng
      result = \
      @validator.validation do
        required do
          scalar :foo
        end
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_required_scope_ok
      @controller.foo = 'HALO'
      result = \
      @validator.validation do
        required
        scalar :foo
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_required_scope_ng
      result = \
      @validator.validation do
        required
        scalar :foo
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_optional_block_no_value_ok
      result = \
      @validator.validation do
        optional do
          scalar :foo
        end
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_optional_block_a_value_ok
      @controller.foo = 'HALO'
      result = \
      @validator.validation do
        optional do
          scalar :foo
        end
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_optional_block_a_value_ng
      @controller.foo = 'HALO'
      result = \
      @validator.validation do
        optional do
          scalar :foo do
            match /Z/
          end
        end
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_ng
      @controller.foo = nil
      result = \
      @validator.validation do
        scalar :foo do
          # nothing to do.
        end
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_match_ok
      @controller.foo = 'HALO'
      result = \
      @validator.validation do
        scalar :foo do
          match /H/
        end
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_match_ng
      @controller.foo = 'HALO'
      result = \
      @validator.validation do
        scalar :foo do
          match /Z/
        end
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_range_string_ok
      @controller.foo = 'bb'
      result = \
      @validator.validation do
        scalar :foo do
          range 'a'..'z'
        end
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_range_string_ng
      @controller.foo = 'bb'
      result = \
      @validator.validation do
        scalar :foo do
          range 'c'..'z'
        end
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_range_integer_ok
      @controller.foo = '5'
      result = \
      @validator.validation do
        scalar :foo do
          range 1..10 do |v|
            v.to_i
          end
        end
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_range_integer_ng
      @controller.foo = '5'
      result = \
      @validator.validation do
        scalar :foo do
          range 1...5 do |v|
            v.to_i
          end
        end
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_validate_ok
      @controller.foo = 'apple'
      result = \
      @validator.validation do
        scalar :foo do
          validate do |v|
            %w[ apple banana orange ].include? v
          end
        end
      end
      assert_equal(true, result)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_validate_ng
      @controller.foo = 'pineapple'
      result = \
      @validator.validation do
        scalar :foo do
          validate do |v|
            %w[ apple banana orange ].include? v
          end
        end
      end
      assert_equal(false, result)
      assert_equal(1, @errors.length)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
