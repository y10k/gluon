# action

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    RESERVED_WORDS = {
      'c' => true,
      'c=' => true,
      'page_hook' => true,
      'page_start' => true,
      'page_end' => true,
      '__view__' => true,
      '__default_view__' => true,
      '__cache_key__' => true,
      '__if_modified__' => true
    }

    EMPTY_PARAMS = {
      :params => {},
      :branches => {}
    }

    class << self
      def parse_params(req_params)
        parsed_params = { :params => {}, :branches => {} }
        for key, value in req_params
          if (key =~ /@/) then
            name = $`
            type = req_params[key]
            unless (req_params.key? name) then
              case (type)
              when 'bool'
                parse_parameter(name.split(/\./), false, parsed_params, name, req_params)
              when 'list'
                parse_parameter(name.split(/\./), [], parsed_params, name, req_params)
              end
            end
          else
            names = key.split(/\./)
            parse_parameter(names, value, parsed_params, key, req_params)
          end
        end
        parsed_params
      end

      def parse_parameter(names, value, parsed_params, key, req_params)
        case (names.length)
        when 0
          # nothing to do.
        when 1
          name = names[0]
          return if (name =~ /[\]\)]$/)
          type = req_params["#{key}@type"] || 'scalar'
          case (type)
          when 'scalar'
            parsed_params[:params][name], = value
          when 'list'
            case (value)
            when Array
              parsed_params[:params][name] = value
            else
              parsed_params[:params][name] = [ value ]
            end
          when 'bool'
            case (value)
            when true, false
              parsed_params[:params][name] = value
            else
              parsed_params[:params][name] = true
            end
          else
            raise "unknown type of #{key}: #{type}"
          end
        else # > 0
          name = names.shift
          unless (parsed_params[:branches].key? name) then
            parsed_params[:branches][name] = { :params => {}, :branches => {} } 
          end
          parse_parameter(names, value, parsed_params[:branches][name], key, req_params)
        end
      end
      private :parse_parameter

      def parse_funcs(req_params)
        parsed_funcs = {}
        for key, value in req_params
          key =~ /\(\)$/ or next
          names = $`.split(/\./)
          name = names.pop
          if (names.empty?) then
            path = ''
          else
            path = names.join('.') + '.'
          end
          parsed_funcs[path] = {} unless (parsed_funcs.key? path)
          parsed_funcs[path][name] = true
        end
        parsed_funcs
      end

      def parse(req_params)
        return parse_params(req_params), parse_funcs(req_params)
      end
    end

    def initialize(controller, rs_context, params, funcs, prefix='')
      @controller = controller
      @c = rs_context
      @params = params
      @funcs = funcs
      @prefix = prefix
      @object = Object.new
    end

    def export?(name, this=@controller)
      if (@object.respond_to? name) then
        false
      else
        if (this.respond_to? name, false) then
          true
        elsif (this.respond_to? name, true) then # deny for private method
          false
        else
          true
        end
      end
    end

    def set_params
      set_parameters(@controller, @params)
      self
    end

    def set_parameters(this, params)
      return if (this.kind_of? Module)
      for name, value in params[:params]
        writer = "#{name}="
        if (export? writer, this) then
          if (this.respond_to? writer) then
            this.__send__(writer, value)
          end
        end
      end
      for name, nested_params in params[:branches]
        if (export? name, this) then
          if (this.respond_to? name) then
            set_parameters(this.__send__(name), nested_params)
          end
        end
      end
    end
    private :set_parameters

    def call_actions
      if (funcs = @funcs[@prefix]) then
        funcs.each_key do |name|
          if (export? name) then
            @controller.__send__(name)
          else
            raise NoMethodError, "undefined method `#{name}' for `#{@controller.class}'"
          end
        end
      end
      self
    end

    def setup
      if (@controller.respond_to? :c=) then
        @controller.c = @c
      end
      self
    end

    def cache_key
      if (@controller.respond_to? :__cache_key__) then
        @controller.__cache_key__
      end
    end

    def modified?(cache_tag)
      if (@controller.respond_to? :__if_modified__) then
        @controller.__if_modified__(cache_tag)
      else
        true
      end
    end

    def page_hook
      if (@controller.respond_to? :page_hook) then
        @controller.page_hook{
          yield
        }
      else
        yield
      end
    end
    private :page_hook

    def apply(renderer)
      r = nil
      page_hook{
        @controller.page_start if (@controller.respond_to? :page_start)
        begin
          set_params
          call_actions
          r = renderer.call(@controller, @c, @params, @funcs, @prefix)
        ensure
          @controller.page_end if (@controller.respond_to? :page_end)
        end
      }
      r
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
