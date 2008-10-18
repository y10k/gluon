#!/usr/local/bin/ruby

require 'gluon'
require 'rack'
require 'test/unit'

module Gluon::Test
  class ValidationTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    include Gluon::Validation

    attr_reader :foo

    def setup
      @env = Rack::MockRequest.env_for('http://foo:8080/bar.cgi')
      @mock = Gluon::Mock.new
      @c = @mock.new_request(@env)
      @foo = nil
      @errors = []
    end

    def test_out_of_validation_block
      validation(@errors) do    # extend Validation::Syntax
      end

      # for validation scope
      assert_raise(NoMethodError) { optional }
      assert_raise(NoMethodError) { required }
      assert_raise(NoMethodError) { validate_one_time_token }
      assert_raise(NoMethodError) { scalar }
      assert_raise(NoMethodError) { list }
      assert_raise(NoMethodError) { bool }
      assert_raise(NoMethodError) { validate }

      # for checker scope
      assert_raise(NoMethodError) { match }
      assert_raise(NoMethodError) { range }
      assert_raise(NoMethodError) { validate }
    end

    def test_out_of_checker_block
      validation(@errors) do
        assert_raise(NoMethodError) { match }
        assert_raise(NoMethodError) { range }
        #assert_raise(NoMethodError) { validate }
      end
    end

    def test_in_checker_block
      @foo = 'HALO'
      validation(@errors) do
        scalar :foo do
          assert_raise(RuntimeError) { optional }
          assert_raise(RuntimeError) { required }
          assert_raise(RuntimeError) { validate_one_time_token }
          assert_raise(RuntimeError) { scalar }
          assert_raise(RuntimeError) { list }
          assert_raise(RuntimeError) { bool }
        end
      end
    end

    def test_validation_empty_ok
      validation(@errors) do
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_ok
      @foo = 'HALO'
      validation(@errors) do
        scalar :foo
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_required_block_ok
      @foo = 'HALO'
      validation(@errors) do
        required do
          scalar :foo
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_required_block_ng
      validation(@errors) do
        required do
          scalar :foo
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_required_block_ok
      @foo = 'HALO'
      validation(@errors) do
        required
        scalar :foo
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_required_block_ng
      validation(@errors) do
        required
        scalar :foo
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_optional_block_no_value_ok
      validation(@errors) do
        optional do
          scalar :foo
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_optional_block_a_value_ok
      @foo = 'HALO'
      validation(@errors) do
        optional do
          scalar :foo
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_optional_block_a_value_ng
      @foo = 'HALO'
      validation(@errors) do
        optional do
          scalar :foo do
            match /Z/
          end
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_ng
      @foo = nil
      validation(@errors) do
        scalar :foo do
          # nothing to do.
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_match_ok
      @foo = 'HALO'
      validation(@errors) do
        scalar :foo do
          match /H/
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_match_ng
      @foo = 'HALO'
      validation(@errors) do
        scalar :foo do
          match /Z/
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_range_string_ok
      @foo = 'bb'
      validation(@errors) do
        scalar :foo do
          range 'a'..'z'
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_range_string_ng
      @foo = 'bb'
      validation(@errors) do
        scalar :foo do
          range 'c'..'z'
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_range_integer_ok
      @foo = '5'
      validation(@errors) do
        scalar :foo do
          range 1..10 do |v|
            v.to_i
          end
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_range_integer_ng
      @foo = '5'
      validation(@errors) do
        scalar :foo do
          range 1...5 do |v|
            v.to_i
          end
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_scalar_validate_ok
      @foo = 'apple'
      validation(@errors) do
        scalar :foo do
          validate do |v|
            %w[ apple banana orange ].include? v
          end
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_scalar_validate_ng
      @foo = 'pineapple'
      validation(@errors) do
        scalar :foo do
          validate do |v|
            %w[ apple banana orange ].include? v
          end
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
    end

    def test_validation_validate_ok
      validation(@errors) do
        validate 'any ok' do
          true
        end
      end
      assert_equal(true, @c.validation)
      assert_equal(0, @errors.length)
    end

    def test_validation_validate_ng
      validation(@errors) do
        validate 'any ng' do
          false
        end
      end
      assert_equal(false, @c.validation)
      assert_equal(1, @errors.length)
      assert_equal('any ng', @errors[0])
    end
  end

  class ValidationTest_method_override < ValidationTest
    def optional
      raise 'optional'
    end

    def required
      raise 'required'
    end

    def validate_one_time_token
      raise 'validate_one_time_token'
    end

    def scalar
      raise 'scalar'
    end

    def list
      raise 'list'
    end

    def bool
      raise 'bool'
    end

    def match
      raise 'match'
    end

    def range
      raise 'range'
    end

    def validate
      raise 'validate'
    end

    def test_out_of_validation_block
      validation(@errors) do    # extend Validation::Syntax
      end

      # for validation scope
      assert_raise(RuntimeError) { optional }
      assert_raise(RuntimeError) { required }
      assert_raise(RuntimeError) { validate_one_time_token }
      assert_raise(RuntimeError) { scalar }
      assert_raise(RuntimeError) { list }
      assert_raise(RuntimeError) { bool }
      assert_raise(RuntimeError) { validate }

      # for checker scope
      assert_raise(RuntimeError) { match }
      assert_raise(RuntimeError) { range }
      assert_raise(RuntimeError) { validate }
    end

    def test_out_of_checker_block
      validation(@errors) do
        assert_raise(RuntimeError) { match }
        assert_raise(RuntimeError) { range }
        #assert_raise(RuntimeError) { validate }
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
