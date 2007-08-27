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
      'page_end' => true
    }

    def initialize(page, rs_context, plugin, prefix='')
      @page = page
      @c = rs_context
      @plugin = plugin.dup
      for name in @plugin.keys
        @plugin["#{name}="] = true
      end
      @prefix = prefix
      @object = Object.new
    end

    def new(page, rs_context, parent_name=nil)
      Action.new(page, rs_context, @plugin, parent_name)
    end

    def funcall(name, *args)
      if (@page.respond_to? name) then
        @page.__send__(name, *args)
      end
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

    def set_plugin
      for name, value in @plugin
        funcall("#{name}=", value)
      end
    end
    private :set_plugin

    def set_params
      param_alist = @c.req.params.find_all{|name, value|
        name[0, @prefix.size] == @prefix &&
          name !~ /\]$/ && name !~ /\)$/
      }

      param_alist.map!{|name, value|
        [ name, name[@prefix.size..-1], value ]
      }

      types = {}
      for long_name, short_name, value in param_alist
        if (short_name =~ /@type$/) then
          types[$`] = value
        end
      end

      param_alist.delete_if{|long_name, short_name, value|
        short_name.index(?.) ||
          short_name =~ /@type$/ ||
          (RESERVED_WORDS.key? short_name) ||
          (@plugin.key? short_name) ||
          (@plugin.key? short_name.to_sym) ||
          (@object.respond_to? short_name)
      }

      for long_name, short_name, value in param_alist
        type = types.delete(short_name) || 'scalar'
        case (type)
        when 'scalar'
          funcall("#{short_name}=", value)
        when 'list'
          case (value)
          when Array
            funcall("#{short_name}=", value)
          else
            funcall("#{short_name}=", [ value ])
          end
        when 'bool'
          funcall("#{short_name}=", true)
        else
          raise "unknown #{long_name}@type: #{type}"
        end
      end

      for name, type in types
        case (type)
        when 'scalar'
          # nothing to do.
        when 'list'
          funcall("#{name}=", [])
        when 'bool'
          funcall("#{name}=", false)
        else
          raise "unknown #{name}@type: #{type}"
        end
      end
    end
    private :set_params

    def call_actions
      name_list = @c.req.params.keys

      name_list.delete_if{|name|
        name[0, @prefix.size] != @prefix || name !~ /\(\)$/
      }

      name_list.map!{|name|
        name[0...-2]
      }

      name_list.delete_if{|name|
        name.index(?.) ||
          name =~ /@type$/ ||
          (RESERVED_WORDS.key? name) ||
          (@plugin.key? name) ||
          (@plugin.key? name.to_sym) ||
          (@object.respond_to? name)
      }

      for name in name_list
        if (@page.respond_to? name) then
          @page.__send__(name)
        else
          raise NameError, "undefined method: #{name}"
        end
      end
    end
    private :call_actions

    def apply
      funcall(:c=, @c)
      set_plugin
      funcall_hook(:page_hook) {
        funcall(:page_start)
        begin
          set_params
          call_actions
          yield
        ensure
          funcall(:page_end)
        end
      }
      self
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
