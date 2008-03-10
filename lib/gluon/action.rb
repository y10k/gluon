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
      '__default_view__' => true
    }

    def initialize(page, rs_context, prefix='')
      @page = page
      @c = rs_context
      @prefix = prefix
      @object = Object.new
    end

    def funcall2(obj, name, *args)
      if (obj.respond_to? name) then
        obj.__send__(name, *args)
      end
    end
    private :funcall2

    def funcall(name, *args)
      funcall2(@page, name, *args)
    end
    private :funcall

    def funcall_hook(name, *args)
      if (@page.respond_to? name) then
        @page.__send__(name, *args) {
          yield
        }
      else
        yield
      end
    end
    private :funcall_hook

    class ParameterScanner
      include Enumerable

      def initialize(prefix, page, params, reserved_words={}, base_obj=Object.new, abort_on_reserved=false)
        @prefix = prefix
        @page = page
        @params = params
        @reserved_words = reserved_words
        @base_obj = base_obj
        @abort_on_reserved = abort_on_reserved
      end

      def each
        for long_name, value in @params
          curr_obj = @page
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
      param_scan = ParameterScanner.new(@prefix, @page, param_alist, RESERVED_WORDS, @object, abort_on_reserved)
      for curr_obj, long_name, short_name, value in param_scan
        yield(curr_obj, long_name, short_name, value)
      end
      self
    end
    private :each_param

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
          funcall2(curr_obj, "#{short_name}=", value)
        when 'list'
          case (value)
          when Array
            funcall2(curr_obj, "#{short_name}=", value)
          else
            funcall2(curr_obj, "#{short_name}=", [ value ])
          end
        when 'bool'
          funcall2(curr_obj, "#{short_name}=", true)
        else
          raise "unknown #{long_name}@type: #{type}"
        end
      end

      each_param(types) do |curr_obj, long_name, short_name, type|
        case (type)
        when 'scalar'
          # nothing to do.
        when 'list'
          funcall2(curr_obj, "#{short_name}=", [])
        when 'bool'
          funcall2(curr_obj, "#{short_name}=", false)
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

    def apply
      r = nil
      funcall(:c=, @c)
      funcall_hook(:page_hook) {
        funcall(:page_start)
        begin
          set_params
          call_actions
          r = yield
        ensure
          funcall(:page_end)
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
