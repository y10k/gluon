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

    module PrintError
      def print_error(message)
        if (@errors) then
          if (message) then
            @errors << message
          else
            @errors << yield
          end
        end

        nil
      end
      private :print_error
    end
    include PrintError

    class Context
      def initialize(validator)
        @validator = validator
      end

      def method_missing(name, *args, &block)
        case (name)
        when :new_context, :validation
          super
        else
          if (@validator.respond_to? name) then
            @validator.__send__(name, *args, &block)
          else
            super
          end
        end
      end
    end

    class Checker
      include PrintError

      def initialize(results, name, value, errors=nil)
        @results = results
        @name = name
        @value = value
        @errors = errors
      end

      def new_context
        Context.new(self)
      end
    end

    class Scalar < Checker
      class << self
        def type_name
          'scalar'
        end

        def check_type?(value)
          value.is_a? String
        end
      end

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
    end

    class List < Checker
      class << self
        def type_name
          'list'
        end

        def check_type?(value)
          value.is_a? Array
        end
      end
    end

    class Bool < Checker
      class << self
        def type_name
          'bool'
        end

        def check_type?(value)
          case (value)
          when TrueClass, FalseClass
            true
          else
            false
          end
        end
      end
    end

    def initialize(controller, errors=nil)
      @controller = controller
      @errors = errors
      @optional = false
      @results = []
    end

    def optional_with(new_optional)
      if (block_given?) then
        save_optional = @optional
        begin
          @optional = new_optional
          r = yield
        ensure
          @optional = save_optional
        end
        r
      else
        @optional = new_optional
        nil
      end
    end
    private :optional_with

    def validate_with(name, checker, error_message=nil, &block)
      value = @controller.__send__(name)
      if (value.nil?) then
        if (@optional) then
          @results << true
        else
          @results << false
          print_error(error_message) {
            "`#{@value}' is not defined at `#{@name}'."
          }
        end
      elsif (checker.check_type? value) then
        @results << true
        if (block_given?) then
          checker.new(@results, name, value, @errors).new_context.instance_eval(&block)
        end
      else
        @results << false
        print_error(error_message) {
          "`#{@value}' is not scalar at `#{@name}'."
        }
      end

      nil
    end
    private :validate_with

    def optional(&block)
      optional_with(true, &block)
    end

    def required(&block)
      optional_with(false, &block)
    end

    def scalar(name, error_message=nil, &block)
      validate_with(name, Scalar, error_message, &block)
    end

    def list(name, error_message=nil, &block)
      validate_with(name, List, error_message, &block)
    end

    def bool(name, error_message=nil, &block)
      validate_with(name, Bool, error_message, &block)
    end

    def validate_one_time_token(error_message=nil)
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
