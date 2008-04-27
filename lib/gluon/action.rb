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

    class << self
      def parse_params(req_params)
        parsed_params = { :params => {}, :branches => {} }
        for key, value in req_params
          if (key =~ /@/) then
            name = $`
            type = req_params[key]
            if (type == 'bool' && ! (req_params.key? name)) then
              parse_parameter(name.split(/\./), false, parsed_params, name, req_params)
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
          path = names.join('.')
          parsed_funcs[path] = {} unless (parsed_funcs.key? path)
          parsed_funcs[path][name] = true
        end
        parsed_funcs
      end

      def parse(req_params)
        return parse_params(req_params), parse_funcs(req_params)
      end
    end

    def initialize(controller, rs_context, prefix='')
      @controller = controller
      @c = rs_context
      @prefix = prefix
      @object = Object.new
    end

    class ParameterScanner
      include Enumerable

      def initialize(prefix, controller, params, reserved_words={}, base_obj=Object.new, abort_on_reserved=false)
        @prefix = prefix
        @controller = controller
        @params = params
        @reserved_words = reserved_words
        @base_obj = base_obj
        @abort_on_reserved = abort_on_reserved
      end

      def each
        for long_name, value in @params
          curr_obj = @controller
          short_name_list = long_name[@prefix.length..-1].split(/\./)
          while (short_name = short_name_list.shift)
            if ((@reserved_words.key? short_name) ||
                (@reserved_words.key? "#{short_name}=") ||
                ((short_name !~ /^to_/) && (@base_obj.respond_to? short_name)))
            then
              if (@abort_on_reserved) then
                raise NoMethodError, "undefined method `#{short_name}' of `#{long_name}'"
              else
                break
              end
            end

            if (short_name_list.empty?) then
              yield(curr_obj, long_name, short_name, value)
            else
              case (short_name)
              when /\[(\d+)\]$/
                name = $`
                index = $1.to_i
                (curr_obj.respond_to? name) or break
                values = curr_obj.__send__(name)
                curr_obj = values[index] or break
              else
                (curr_obj.respond_to? short_name) or break
                curr_obj = curr_obj.__send__(short_name)
              end
            end
          end
        end

        self
      end
    end

    def each_param(param_alist, abort_on_reserved=false)
      param_scan = ParameterScanner.new(@prefix, @controller, param_alist, RESERVED_WORDS, @object, abort_on_reserved)
      for curr_obj, long_name, short_name, value in param_scan
        yield(curr_obj, long_name, short_name, value)
      end
      self
    end
    private :each_param

    def funcall(obj, name, *args)
      if (obj.respond_to? name) then
        obj.__send__(name, *args)
      end
    end
    private :funcall

    def set_params
      param_alist = @c.req.params.find_all{|name, value|
        name.length > @prefix.length && name[0, @prefix.length] == @prefix
      }

      param_alist.delete_if{|name, value|
        name =~ /\]$/ || name =~ /\)$/
      }

      types = {}
      param_alist.delete_if{|name, value|
        if (name =~ /@type$/) then
          types[$`] = value
          true
        end
      }

      each_param(param_alist) do |curr_obj, long_name, short_name, value|
        type = types.delete(long_name) || 'scalar'
        case (type)
        when 'scalar'
          funcall(curr_obj, "#{short_name}=", value)
        when 'list'
          case (value)
          when Array
            funcall(curr_obj, "#{short_name}=", value)
          else
            funcall(curr_obj, "#{short_name}=", [ value ])
          end
        when 'bool'
          funcall(curr_obj, "#{short_name}=", true)
        else
          raise "unknown #{long_name}@type: #{type}"
        end
      end

      each_param(types) do |curr_obj, long_name, short_name, type|
        case (type)
        when 'scalar'
          # nothing to do.
        when 'list'
          funcall(curr_obj, "#{short_name}=", [])
        when 'bool'
          funcall(curr_obj, "#{short_name}=", false)
        else
          raise "unknown #{long_name}@type: #{type}"
        end
      end
    end
    private :set_params

    def call_actions
      param_alist = @c.req.params.find_all{|name, value|
        name.length > @prefix.length && name[0, @prefix.length] == @prefix && name =~ /\(\)$/
      }

      param_alist.map!{|name, value|
        [ name[0...-2], value ]
      }

      each_param(param_alist, true) do |curr_obj, long_name, short_name, value|
        case (curr_obj)
        when Class, Module
          next                  # skip import
        end
        curr_obj.__send__(short_name)
      end
    end
    private :call_actions

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
          r = renderer.call(@controller, @c, @prefix)
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
