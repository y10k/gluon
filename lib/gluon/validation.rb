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

      def validation_name
        @name
      end

      def validation_value
        @value
      end

      def validation_type
        self.class.type_name
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
        emsg = error_message ||
          "value at `#{@name}' should#{nt} be match to `#{regexp}'."
        validate_scalar(emsg, negate) {
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
        emsg = error_message ||
          "value at `#{@name}' is#{nt} out of range `#{range}'.",
        validate_scalar(emsg, negate) {
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

      def _validate_list(list_validator, error_message=nil, negate=false)
        if (negate) then
          validate = proc{|v| ! yield(v) }
        else
          validate = proc{|v| yield(v) }
        end

        if (@value.__send__(list_validator, &validate)) then
          @results << true
        else
          @results << false
          print_error(error_message ||
                      "list at `#{@name}' is invalid.")
        end

        nil
      end
      private :_validate_list

      def validate_list_all(error_message=nil, negate=false)
        _validate_list(:all?,
                       error_message ||
                       "all value of list at `@name' is invalid.",
                       negate)
      end

      alias validate_list validate_list_all
      alias validate validate_list

      def match_list_all(regexp, error_message=nil, negate=false)
        nt = (negate) ? ' not' : ''
        emsg = error_message ||
          "all value of list at `#{@name}' should#{nt} be match to `#{regexp}'.",
        validate_list_all(emsg, negate) {|v|
          regexp === v
        }
      end

      alias match_list match_list_all
      alias match match_list

      def not_match_list_all(regexp, error_message=nil)
        match_list_all(regexp, error_message, true)
      end

      alias not_match_list not_match_list_all
      alias not_match not_match_list

      def range_list_all(range, error_message=nil, negate=false)
        nt (negate) ? ' not' : ''
        emsg = error_message ||
          "all value at `#{@name}' is#{nt} out of range `#{range}'."
        validate_list_all(emsg, negate) {|v|
          if (block_given?) then
            v = yield(v)
          end
          range.include? v
        }
      end

      alias range_list range_list_all
      alias range range_list

      def not_range_list_all(range, error_message=nil)
        range_list_all(range, error_message, true)
      end

      alias not_range_list not_range_list_all
      alias not_range not_range_list

      def validate_list_any(error_message=nil, negate=false)
        _validate_list(:any?,
                       error_message ||
                       "any value of list at `@name' is invalid.",
                       negate)
      end

      def match_list_any(regexp, error_message=nil, negate=false)
        nt = (negate) ? ' not' : ''
        emsg = error_message ||
          "any value of list at `#{@name}' should#{nt} be match to `#{regexp}'.",
        validate_list_any(emsg, negate) {|v|
          regexp === v
        }
      end

      def not_match_list_any(regexp, error_message=nil)
        match_list_any(regexp, error_message, true)
      end

      def range_list_any(range, error_message=nil, negate=false)
        nt (negate) ? ' not' : ''
        emsg = error_message ||
          "any value at `#{@name}' is#{nt} out of range `#{range}'."
        validate_list_any(emsg, negate) {|v|
          if (block_given?) then
            v = yield(v)
          end
          range.include? v
        }
      end

      def not_range_list_any(range, error_message=nil)
        range_list_any(range, error_message, true)
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
                    "`#{@value}' is not #{checker.type_name} at `#{@name}'.")
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

    def validate(error_message)
      if (yield) then
        @results << true
      else
        @results << false
        if (@errors) then
          @errors << error_message
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
        module_eval(<<-EOF, "#{__FILE__},#{Syntax}\##{name}", __LINE__ + 1)
          def #{name}(*args, &block)
            if (@__gluon_checker__) then
              raise %q"not in validation checker block for `#{name}'."
            end
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
              if (@__gluon_checker__) then
                raise %q"not nested validation checker block for `#{name}'."
              end
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
        validation_name
        validation_value
        validation_type

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

      def validate(*args, &block)
        if (@__gluon_validator__) then
          if (@__gluon_checker__) then
            @__gluon_checker__.validate(*args, &block)
          else
            @__gluon_validator__.validate(*args, &block)
          end
        else
          super
        end
      end
    end

    def validation(errors=nil)
      r = Validator.new(self, errors).validation{|validator|
        if (@__gluon_validator__) then
          raise 'not nested validation.'
        end
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

      if (@c.validation.nil?) then
        @c.validation = r
      else
        if (@c.validation) then
          @c.validation = r
        else
          # violation by previous validation check.
        end
      end

      nil
    end
    private :validation
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
