# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'forwardable'

module Gluon
  class Validator
    # for ident(1)
    CVS_ID = '$Id$'

    class ScalarAttribute
      def initialize(results, name, value, errors=nil)
        @results = results
        @name = name
        @value = value
        @errors = errors
      end

      def print_error(error_message)
        if (@errors) then
          if (error_message) then
            @errors << error_message
          else
            @errors << yield
          end
        end
      end
      private :print_error

      def match(regexp, error_message=nil)
        if (regexp === @value) then
          @results << true
        else
          @results << false
          print_error(error_message) {
            "value at `#{@name}' should be match to `#{regexp}'."
          }
        end

        nil
      end

      def range(range, error_message=nil)
        if (block_given?) then
          v = yield(@value)
        else
          v = @value
        end

        if (range.include? v) then
          @results << true
        else
          @results << false
          print_error(error_message) {
            "value at `#{@name}' is out of range `#{range}'."
          }
        end

        nil
      end

      def validate(error_message=nil)
        if (yield(@value)) then
          @results << true
        else
          @results << false
          print_error(error_message) {
            "value at `#{@name}' is invalid."
          }
        end

        nil
      end

      class Context
        extend Forwardable

        def initialize(scalar_validator)
          @scalar_validator = scalar_validator
        end

        def_delegator :@scalar_validator, :match
        def_delegator :@scalar_validator, :range
        def_delegator :@scalar_validator, :validate
      end

      def new_context
        Context.new(self)
      end
    end

    class ListAttribute
    end

    def initialize(controller, errors=nil)
      @controller = controller
      @errors = errors
      @optional = false
      @results = []
    end

    def optional
      if (block_given?) then
        save_optional = @optional
        begin
          @optional = true
          r = yield
        ensure
          @optional = save_optional
        end
        r
      else
        @optional = true
        nil
      end
    end

    def required
      if (block_given?) then
        save_optional = @optional
        begin
          @optional = false
          r = yield
        ensure
          @optional = save_optional
        end
        r
      else
        @optional = false
        nil
      end
    end

    def scalar(name, error_message=nil, &block)
      value = @controller.__send__(name)
      case (value)
      when NilClass
        unless (@optional) then
          @results << false
          if (@errors) then
            @errors << (error_message ||
                        "`#{@value}' is not scalar at `#{@name}'.")
          end
        end
      when String
        scalar_validator = ScalarAttribute.new(@results, name, value, @errors)
        scalar_context = scalar_validator.new_context
        scalar_context.instance_eval(&block) if block_given?
      else
        @results << false
        if (@errors) then
          @errors << (error_message ||
                      "`#{@value}' is not scalar at `#{@name}'.")
        end
      end

      nil
    end

    def list(name, &block)
      values = @controller.__send__(name)
      list_validator = ListAttribute.new(@results, name, values, @errors)
      list_context = list_validator.new_context
      list_context.instance_eval(&block)
      nil
    end

    def bool(name, error_message=nil)
      value = @controller.__send__(name)
      case (value)
      when true, false
        @results << true
      else
        @results << false
        if (@errors) then
          @errors << (error_message || "value at `#{name}' is not boolean.")
        end
      end
      nil
    end

    def validate_ont_time_token(error_message=nil)
      if (@controller.one_time_token_valid?) then
        @results << true
      else
        @results << false
        if (@errors) then
          @errors << (error_message || 'Not reload form.')
        end
      end
      nil
    end

    class Context
      extend Forwardable

      def initialize(validator)
        @validator = validator
      end

      def_delegator :@validator, :optional
      def_delegator :@validator, :required
      def_delegator :@validator, :scalar
      def_delegator :@validator, :list
      def_delegator :@validator, :bool
      def_delegator :@validator, :validate_ont_time_token
    end

    def validation(&block)
      context = Context.new(self)
      context.instance_eval(&block)
      @results.all?
    end
  end

  module Validation
    # for ident(1)
    CVS_ID = '$Id$'

    def validation(errors=nil, &block)
      validator = Validator.new(self, @c, errors)
      @c.validation = validator.validate(&block)
      nil
    end
    private :validation
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
