# action

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, rs_context, plugin, prefix='')
      @page = page
      @c = rs_context
      @plugin = plugin
      @prefix = prefix
      @object_methods = {}
      Object.instance_methods.each do |name|
        @object_methods[name] = true
      end
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
          types[short_name] = value
        end
      end

      param_alist.delete_if{|long_name, short_name, value|
        short_name.index(?.) ||
          short_name =~ /@type$/ ||
          (@plugin.key? short_name) ||
          (@plugin.key? short_name.to_sym)
      }

      for long_name, short_name, value in param_alist
        type = types["#{short_name}@type"] || 'scalar'
        case (type)
        when 'scalar'
          funcall("#{short_name}=", value)
        when 'bool'
          funcall("#{short_name}=", true)
        else
          raise "unknown #{long_name}@type: #{type}"
        end
        types.delete("#{short_name}@type")
      end

      for key, type in types
        case (type)
        when 'scalar'
          # nothing to do.
        when 'bool'
          name = key.sub(/@type$/, '')
          funcall("#{name}=", false)
        else
          raise "unknown #{long_name}@type: #{type}"
        end
      end
    end
    private :set_params

    def call_actions
      @c.req.params.keys.find_all{|n|
        n[0, @prefix.size] == @prefix && n =~ /\(\)$/
      }.map{|n|
        n[@prefix.size..-3]
      }.reject{|n|
        n.index(?.) || (@object_methods.key? n)
      }.each do |name|
        @page.__send__(name)
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
