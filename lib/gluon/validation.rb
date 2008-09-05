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
          @errors << message
        end
        nil
      end
      private :print_error
    end
    include PrintError

    class Checker
      include PrintError

      def initialize(results, name, value, errors=nil)
        @results = results
        @name = name
        @value = value
        @errors = errors
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

      def validate_scalar(error_message=nil, negate=false)
        r = yield(@value)
        r = ! r if negate
        if (r) then
          @results << true
        else
          @results << false
          print_error(error_message ||
                      "value at `#{@name}' is invalid.")
        end

        nil
      end

      alias validate validate_scalar

      def match_scalar(regexp, error_message=nil, negate=false)
        nt = (negate) ? ' not' : ''
        validate_scalar(error_message ||
                 "value at `#{@name}' should#{nt} be match to `#{regexp}'.",
                 negate) {
          regexp === @value
        }
      end

      alias match match_scalar

      def not_match_scalar(regexp, error_message=nil)
        match_scalar(regexp, error_message, true)
      end

      alias not_match not_match_scalar

      def range_scalar(range, error_message=nil, negate=false)
        nt = (negate) ? ' not' : ''
        validate_scalar(error_message ||
                 "value at `#{@name}' is#{nt} out of range `#{range}'.",
                 negate) {
          if (block_given?) then
            v = yield(@value)
          else
            v = @value
          end
          range.include? v
        }
      end

      alias range range_scalar

      def not_range_scalar(range, error_message=nil)
        range_scalar(range, error_message, true)
      end

      alias not_range not_range_scalar
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

    def validate_with(name, checker, error_message=nil)
      value = @controller.__send__(name)
      if (value.nil?) then
        if (@optional) then
          @results << true
        else
          @results << false
          print_error(error_message ||
                      "`#{@value}' is not defined at `#{@name}'.")
        end
      elsif (checker.check_type? value) then
        @results << true
        if (block_given?) then
          yield(checker.new(@results, name, value, @errors))
        end
      else
        @results << false
        print_error(error_message ||
                    "`#{@value}' is not scalar at `#{@name}'.")
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

    def validation
      @results.clear
      yield(self)
      @results.all?
    end
  end

  module Validation
    # for ident(1)
    CVS_ID = '$Id$'

    module Syntax
      %w[ optional required validate_one_time_token ].each do |name|
        module_eval(<<-EOF, "#{__FILE__}: #{Syntax}\##{name}", __LINE__ + 1)
          def #{name}(*args, &block)
            if (@__gluon_validator__) then
              @__gluon_validator__.#{name}(*args, &block)
            else
              super
            end
          end
        EOF
      end

      %w[ scalar list bool ].each do |name|
        module_eval(<<-EOF, "#{__FILE__}: #{Syntax}\##{name}", __LINE__ + 1)
          def #{name}(*args)
            if (@__gluon_validator__) then
              if (block_given?) then
                @__gluon_validator__.#{name}(*args) {|checker|
                  @__gluon_checker__ = checker
                  begin
                    r = yield
                  ensure
                    @__gluon_checker__ = nil
                  end
                  r
                }
              else
                @__gluon_validator__.#{name}(*args)
              end
            else
              super
            end
          end
        EOF
      end

      %w[
        validate
        match not_match
        range not_range

        validate_scalar
        match_scalar not_match_scalar
        range_scalar not_range_scalar

        validate_list
        match_list not_match_list
        range_list not_range_list

        validate_list_all
        match_list_all not_match_list_all
        range_list_all not_range_list_all

        validate_list_any
        match_list_any not_match_list_any
        range_list_any not_range_list_any
      ].each do |name|
        module_eval(<<-EOF, "#{__FILE__}: #{Syntax}\##{name}", __LINE__ + 1)
          def #{name}(*args, &block)
            if (@__gluon_checker__) then
              @__gluon_checker__.#{name}(*args, &block)
            else
              super
            end
          end
        EOF
      end
    end

    def validation(errors=nil)
      @c.validation = Validator.new(self, errors).validation{|validator|
        @__gluon_validator__ = validator
        begin
          class << self
            unless (include? Syntax) then
              include Syntax
            end
          end
          r = yield
        ensure
          @__gluon_validator__ = nil
        end
        r
      }
      nil
    end
    private :validation
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
